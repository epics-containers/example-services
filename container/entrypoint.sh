#!/bin/bash

DIR=/tmp/example-services$$
mkdir -p "$DIR"

rsync -a --exclude=.git --exclude=container "/workspace/" "$DIR"

cd "$DIR"
docker compose up -d
