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

That's it. With these settings you can use podman compose ... at any time without needing a module load. You may update the docker-compose version in the path as needed.

## Other workstations

All other linux should install podman and docker-compose and have the following in their `~/.profile`:

```bash
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
alias docker=podman
```

**Debian Distros**
```bash
sudo apt install podman docker-compose-v2
```

**RPM distros**
```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install podman docker-compose-plugin
```

**MacOS**

- Install podman desktop.
  - https://podman-desktop.io/docs/installation/macos-install
- Install docker-compose plugin using instructions for your guest distro above.

**Windows**

- Install podman desktop with WSL2 and enable docker compose integration.
  - https://podman-desktop.io/docs/installation/windows-install
- Install docker-compose plugin using instructions for your guest distro above.

## Further Notes

### Profiles

This project uses compose profiles. If you use them then you need to tell vscode which profile to use.

You can globally set the environment variable `COMPOSE_PROFILES` but it is easier to use the devcontainer.json setting `runServices` to list the services that the devcontainer should start.

e.g.
```json
	// the services from the compose.yaml that we want to run
	"runServices": [
		"bl01t-di-cam-01-dev",
		"phoebus",
		"ca-gateway",
		"pvagw"
	],
```
