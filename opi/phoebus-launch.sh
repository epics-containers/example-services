#!/bin/bash

# podman launcher for phoebus container

thisdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

args=${args}"
-it
-e DISPLAY
--net host
--security-opt=label=type:container_runtime_t
"

mounts="
-v=/tmp:/tmp
-v=${thisdir}:/workspace
"

settings="
-resource /workspace/demo.bob
-settings /workspace/settings.ini
"

set -x
podman run ${mounts} ${args} ghcr.io/epics-containers/ec-phoebus:latest ${settings} "${@}"

