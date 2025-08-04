FROM ghcr.io/diamondlightsource/ubuntu-devcontainer

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    docker-compose-v2 rsync && \
    rm -rf /var/lib/apt/lists/*

COPY . /workspace
WORKDIR /workspace

ENTRYPOINT [ "container/entrypoint.sh" ]
