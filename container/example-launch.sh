#!/bin/bash

podman run --rm -it --security-opt label=disable -e DISPLAY -v /tmp:/tmp -v $XDG_RUNTIME_DIR/podman/podman.sock:/var/run/docker.sock example-services:latest
