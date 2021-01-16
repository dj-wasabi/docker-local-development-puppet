#!/usr/bin/env bash

set -euo pipefail

function createLockFile() {
  local _TYPE=$1
  if [[ -f "${LOCK_DIR}/${_TYPE}.lck" ]]
    then  echo "We already have an ${_TYPE} running."
          exit 1
    else  touch "${LOCK_DIR}/${_TYPE}.lck"
  fi 
}

function deleteLockFile() {
  local _TYPE=$1
  if [[ -f "${LOCK_DIR}/${_TYPE}.lck" ]]
    then  rm "${LOCK_DIR}/${_TYPE}.lck"
    else  echo "We don't have an ${_TYPE} running."
          exit 1
  fi 
}

function getPuppetMasterIP() {
  local IP
  IP=$(docker exec -it puppet cat /etc/hosts | tail -n 1 | awk '{print $1}')
  echo "$IP"
}

function logMessage() {
  local MESSAGE=$1
  echo "$(date "+%Y-%m-%d %H:%M:%S") - ${MESSAGE}"
}

function prePareConfig() {
  if [[ -z ${LOCK_DIR} ]]
    then  echo "ERROR - 'LOCK_DIR' is not configured in configuration file."
          exit 1
  fi
  if [[ ! -d "${LOCK_DIR}" ]]
    then  mkdir "${LOCK_DIR}"
  fi
}

function prePareAgent() {
  # Install Puppet Agent
  logMessage "Installing puppet in agent"
  docker exec -it agent yum install -y https://yum.puppet.com/puppet6-release-el-7.noarch.rpm > /dev/null 2>&1
  docker exec -it agent yum install -y puppet-agent > /dev/null 2>&1
}

function runPuppetAgent() {
  docker exec -it agent /opt/puppetlabs/bin/puppet agent -t
}

function startPuppetAgent() {
  createLockFile "agent"
  logMessage "Starting the Agent container"
  docker-compose up -d agent
}

function startPuppetMaster(){
  createLockFile "server"
  logMessage "Starting the Puppet master container"
  docker-compose up -d puppet > /dev/null 2>&1

  # START_COUNT=0
  # while [ $START_COUNT -lt 15 ]
  # do
  #   echo "jasasas"
  #   START_COUNT=$(( $START_COUNT + 1 ))
  # done
  # while [[ docker logs -f puppet | grep 'Puppet Server Update Service has successfully started and will run in the background' ]]; do
  #     echo 'asasas'
  #     sleep 1
  # done
}

function startAll(){
  prePareConfig
  # Start the Master
  startPuppetMaster

  # Start and prepare the Agent for puppet runs
  PUPPET_MASTER_IP=$(getPuppetMasterIP)
  export PUPPET_MASTER_IP="${PUPPET_MASTER_IP}"
  startPuppetAgent
  prePareAgent
}


function stopAll() {
  logMessage "Stopping and removing containers"
  docker-compose stop agent puppet > /dev/null 2>&1
  docker-compose rm -f agent puppet > /dev/null 2>&1
  logMessage "Everything is stopped"
  deleteLockFile "server"
  deleteLockFile "agent"
}

# Verify that Docker is runnig.
if [[ $(docker ps > /dev/null 2>&1; echo $?) -ne 0 ]]
  then  echo "ERROR - Docker is not running"
        exit 1
fi

# Sourcing the docker-compose configuration otherwise we fail.
if [[ ! -f docker-compose.config ]]
  then  echo "ERROR - docker-compose.config not found"
        exit 1
fi

# shellcheck disable=SC1091
source docker-compose.config

export DC_AGENT_IMAGE=${DC_AGENT_IMAGE}

while getopts 'dash' OPTION; do
  case "$OPTION" in
    a)
      # Run puppet agent
      runPuppetAgent
      ;;

    d)
      # Destroy everything
      stopAll
      ;;

    s)
      # Start all
      startAll
      ;;

    h)
      help
      exit 0
      ;;

    ?)
      help
      exit 1
      ;;
  esac
done
shift "$(( OPTIND - 1))"