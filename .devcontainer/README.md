# Podman Compose Devcontainer

This devcontainer uses docker compose to start up a simulation beamline.

It is intended to be used with podman rootless containers.

It also serves as an example of how to get podman and docker-compose working together with vscode.

## compose.yaml

Your compose.yaml can be arbitrarily complex. But one of the services it creates must be the 'devcontainer' that vscode will connect to. This is specified by service name in the devcontainer.json file.
That service must mount the workspace folder.

See [the example mount](https://github.com/epics-containers/example-services/blob/9414c026191897082d8097ee2d004ccc665077ba/services/bl01t-di-cam-01/compose.yml#L28-L29) in this repo's bl49p-di-dcam-01 service

Additionally you will want that container to have suffient tools in it. At a minimum it requires `git`.


## One Time Setup

Create a podman service and socket for docker-compose to use. This need only be done once per workstation.

```bash
systemctl enable --user podman.socket --now
```

Change the following setting in vscode:

- dev.containers.dockerPath: `podman`

## How to setup on a DLS workstation

Add this to your `~/.profile` and logout and back in:

```bash
export PATH=/dls_sw/apps/docker-compose/2.33.1/bin/:$PATH
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
alias docker=podman
```

That's it.

## Other workstations

**Debian Distros**
```bash
sudo apt install podman docker-compose-v2
```

**RPM distros**
```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install git docker-compose-plugin
```

**MacOS**

install podman desktop and enable docker compose integration.

**Windows**

install WSL2 and docker desktop and enable docker desktop integration for your WSL2 distro.

WARNING: docker desktop is a paid product for work machines. Try podman desktop instead, but I've not tested it.
