#! /bin/bash

# Setup environment variables required to launch the services described in this
# repo. A standard install of docker compose and permission to run docker
# are the only other requirements (membership of the docker group).
#
# docker compose may be backed by podman or docker container engines, see
# https://epics-containers.github.io/main/tutorials/setup_workstation.html.


# This script must be sourced
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "ERROR: Please source this script (source ./environment.sh)"
    exit 1
fi

# Environment variables for the EPICS IOC ports. Pick a Unique BASE
# to allow multiple compose beamlines to run on the same host.
# BASE values should be separated by 20.
#
BASE=5094
#
export EPICS_CA_SERVER_PORT=$BASE # defaults to 5064
export EPICS_CA_REPEATER_PORT=$(( $BASE + 1 )) # defaults to 5065
export EPICS_PVA_SERVER_PORT=$(( $BASE + 11 )) # defaults to 5075

export CA_SUBNET=170.$(( $BASE % 256 )).0.0/16
export CA_BROADCAST=170.$(( $BASE % 256 )).255.255

export EPICS_PVA_NAME_SERVERS=localhost:${EPICS_PVA_SERVER_PORT}
export EPICS_CA_NAME_SERVERS=localhost:${EPICS_CA_SERVER_PORT}

export EPICS_CA_ADDR_LIST=127.0.0.1

# update configuration files that depend on the above environment variables
cat services/phoebus/config/settings.template |
  sed -e "s/5064/$EPICS_CA_SERVER_PORT/g" \
      -e "s/5065/$EPICS_CA_REPEATER_PORT/g" \
      -e "s/5075/$EPICS_PVA_SERVER_PORT/g" > services/phoebus/config/settings.ini
cat services/pvagw/config/pvagw.template |
  sed -e "s/172.20.255.255/$CA_BROADCAST/g" \
      -e "s/5075/$EPICS_PVA_SERVER_PORT/g" > services/pvagw/config/pvagw.config

# if there is a docker-compose module then load it
if [[ $(module avail docker-compose 2>/dev/null) != "" ]] ; then
    module load docker-compose
fi

# podman vs docker differences.
if podman version &> /dev/null && [[ -z $USE_DOCKER ]] ; then
    USER_ID=0; USER_GID=0
    DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
    docker=podman
else
    USER_ID=$(id -u); USER_GID=$(id -g)
    unset DOCKER_HOST
    docker=docker
fi
echo using $docker as container engine

# ensure local container users can access X11 server
xhost +SI:localuser:$(id -un)

# Set up the environment for compose ###########################################

# set user id for the phoebus container for easy X11 forwarding.
export UIDGID=$USER_ID:$USER_GID
# choose test profile for docker compose
export COMPOSE_PROFILES=test
# for test profile our ca-gateway publishes PVS on the loopback interface
export EPICS_CA_ADDR_LIST=127.0.0.1
# make a short alias for docker-compose for convenience
alias dc='$docker compose'
