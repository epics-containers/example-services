# Beamline bl01t Example Simulation Beamline

This repository holds the definition of example beamline bl01t. It serves as a useful training tool for trying out epics-containers on a local workstation.

It also serves as an example of how to deploy epics-containers IOCs using docker compose for those facilities that are not planning on using Kubernetes.

The following containers are defined:
- ca-gateway
- pva-gateway
- phoebus
- a motor simulation IOC
- an area detector simulation IOC
- an additional simple example IOC

The top level compose.yml file represents a set of IOCs and other services that would be deployed to a single IOC server or workstation. It includes a separate compose file for each of the services listed above.

Potentially you could have one top level compose file per IOC server in a multi-server setup.

## Initial Setup

To try this example requires only git, docker compose and a container runtime (docker or podman).

See [quickstart instructions](https://epics-containers.github.io/main/how-to/compose-quickstart.html) for details on how to install these on most platforms.


## Local Testing Environment

To launch a test environment on a workstation, including phoebus perform the following steps:

```bash
git clone https://github.com/epics-containers/example-services.git
cd example-services
source ./environment.sh
docker compose up -d
```

NOTE: -d detaches from the containers. You may omit this if you would prefer to follow the logs of all the containers - these combined logs include a colour coded prefix to make them more legible.


## Experimenting
You can now try the following (we use `dc` as a short alias for `docker compose`):

```bash
# use caget/put locally
export EPICS_CA_ADDR_LIST=127.0.0.1:5094
caget BL01T-DI-CAM-01:DET:Acquire_RBV

# OR if you don't have caget/put locally then use one of the containers instead:
docker compose exec bl01t-ea-test-01 bash
export EPICS_CA_ADDR_LIST=127.0.0.1:5094
caget BL01T-DI-CAM-01:DET:Acquire_RBV

# attach to logs of a service (-f follows the logs, use ctrl-c to exit)
docker compose logs bl01t-di-cam-01 -f
# stop a service
docker compose stop bl01t-di-cam-01
# restart a service
docker compose start bl01t-di-cam-01
# attach to a service stdio
docker compose attach bl01t-di-cam-01
# exec a process in a service
docker compose exec bl01t-di-cam-01 bash
# delete a service (deletes the container)
docker compose down bl01t-di-cam-01
# create and launch a single service (plus its dependencies)
docker compose up bl01t-di-cam-01 -d
# close down and delete all the containers
# volumes are not deleted to preserve the data
docker compose down
```

NOTE: sometimes the pva-gateway will not terminate before `docker compose down` times out and you will see an error. If this happens then you can run `docker compose down` again and it should then remove the pva-gateway container.

# Phone Deployment

`compose-phone.yaml` is a separate, cut-down deployment for a single small host such as the arm64 Debian VM in the Android Linux Terminal. It runs only the camera and motor IOCs (`bl01t-di-cam-01`, `bl01t-mo-sim-01`) from multi-arch (amd64 + arm64) generic IOC images, reusing their configs in `services/*/config`. There are no gateways, phoebus or init service: the IOCs use the host network, each with its own ports (camera CA 5064 / PVA 5075, motor CA 6064 / PVA 6075).

The screens are viewed with [bobview](https://github.com/gilesknap/bobview), which runs natively on the phone rather than in a container. If bobview is missing (or built for the wrong architecture), `phone-launch.sh` installs it into `~/.local` with bobview's own installer, which fetches the release build for the machine (aarch64 or x86_64). It may also need `sudo apt install libxkbcommon0 libwayland-client0 libegl1 libgl1-mesa-dri`. Then:

```bash
git clone https://github.com/epics-containers/example-services.git
cd example-services
./phone-launch.sh        # start the IOCs and open bobview on opi/demo.bob
./phone-launch.sh stop   # stop the IOCs
```

`phone-launch.sh` makes sure the podman API service is running and sets `DOCKER_HOST` to its socket (set `USE_DOCKER=1` to use docker instead), then uses `docker compose` (or `podman compose`) with `compose-phone.yaml`, waits for the IOCs to write their auto-generated screens into `opi/auto-generated/` (which `demo.bob` links to), and runs bobview with the CA/PVA client settings pointing at the IOC ports. The IOCs keep running when bobview is closed; run the script again to reopen it. The main `compose.yaml` is unchanged by this.

# Deploy To Beamline Servers

TODO: although this will work for CA, there is not yet a solution for PVA. PVA UDP traffic will not route into a container. Two possible solutions are:

 - put all the IOCs in host network and do not use gateways
 - put the only the pva gateway in host network and have it's container generate a EPICS_PVA_NAME_SERVERS setting that lists all the local IOCS container network IP addresses. (I have used this approach for routing into kubernetes IOCs running in the CNI)

To deploy IOCs to a server, clone this repo and run the following command from the repo root:

```bash
docker compose --profile deploy up -d
```

or for a multiple server repo:
```bash
docker compose --profile deploy -f my_server_01.yml up -d
```

IMPORTANT: if you are using docker then IOCs deployed this way will automatically be brought up again on server reboot. podman will not do this by default because it is running in user space - there are workarounds for this but podman is not recommended for this purpose.

The gold standard for orchestrating these containers in production is Kubernetes. See https://epics-containers.github.io/main/tutorials/setup_k8s.html. Although compose is really useful for development and testing, Kubernetes is far superior for managing services across a cluster of hosts.

# Compose goals

These goals for switching to compose (from bespoke code in the `ec` tool) have all been met:

- be as DRY as possible
- work with docker-compose controlling either docker or podman
- enable isolated testing where PVs are not available to the whole subnet
- include separate profiles for:
  - local testing - including phoebus OPI
  - deployment to a beamline server - this requires either:
    - network host on the IOCs
    - a ca-gateway and pva-gateway
- structure so that there is a compose file per server and per IOC
- remove need for custom code/scripts to deploy/manage the IOCs
- also allow PV isolation on servers with a ca-gateway to enable access

# DLS Troubleshooting for docker compose module

Some users who have set up podman sockets in the past may get errors with `module load docker-compose`. If you do then do the following and then re-run it.
```bash
/dls_sw/apps/setup-podman/setup.sh
sed -i ~/.config/containers/containers.conf -e '/label=false/d' -e '/^\[containers\]$/a label=false'
```
