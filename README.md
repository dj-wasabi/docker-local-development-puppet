# Docker local development Puppet

Toc
- [Docker local development Puppet](#docker-local-development-puppet)
  * [Introduction](#introduction)
  * [Configuration](#configuration)
    + [General](#general)
    + [Agent](#agent)
  * [Command line](#command-line)

## Introduction

This is my silly attempt to locally develop Puppet Modules without using Vagrant in the same way as how Molecule work with Ansible. Not sure if it is a mistake for using BASH, but maybe in the future it will go to Python as well.

## Configuration

Configuration will be done via the `docker-compose.conf` file. It is basically a key=value file and will be sourced in the `BASH` `puppet.sh` script.

### General

|Configuration   | Description   |
|---|---|
|LOCK_DIR | The location on the local system where lck files are placed.|

### Agent

|Configuration   | Description   |
|---|---|
|DC_AGENT_IMAGE | The location to the Docker image to be used.|

## Command line

```sh
$ ./puppet.sh -h
This script will start 2 Docker containers, 1 Puppet master and 1 Puppet agent.
The Docker image for the Puppet Agent can be configured in the 'docker-compose.conf' file

	-a	Executing the 'puppet agent -t' command in the Puppet agent container.
	-d	Will stop and destroy the environment.
	-s	Will start the puppet master and the agent containers.
	-h	Will print this help message.

Note:
	Please make sure that Docker is running.
```