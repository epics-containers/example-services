#!/bin/bash

THIS_DIR=$(dirname "$(readlink -f "$0")")

podman build -t example-services "$THIS_DIR/.." -f ${THIS_DIR}/Dockerfile