#!/bin/bash

podman run -it -v /tmp:/tmp -v $XDG_RUNTIME_DIR/podman/podman.sock:/var/run/docker.sock example-services:latest
