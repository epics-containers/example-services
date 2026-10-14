#!/bin/bash

# Launch the phone deployment: start the IOCs in compose-phone.yaml and then
# open the demo screen in bobview, which runs natively (it is a GUI binary,
# not a container).
#
# usage:
#   ./phone-launch.sh         start the IOCs (if not running) and open bobview
#   ./phone-launch.sh stop    stop the IOCs
#
# The IOCs keep running after bobview is closed; run this again to reopen it.

set -e

cd "$(dirname "$(readlink -f "$0")")"

# with podman, make sure its API service is running and point DOCKER_HOST at
# it so that 'docker compose' (or the docker-compose behind 'podman compose')
# talks to podman. Set USE_DOCKER to use docker instead.
if podman version &> /dev/null && [[ -z ${USE_DOCKER} ]]; then
    sock=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock
    if systemctl --user enable --now podman.socket &> /dev/null; then
        :  # socket activation starts the service on first use
    elif [[ ! -S ${sock} ]]; then
        # no systemd user session: run the service directly in the background
        mkdir -p "$(dirname "${sock}")"
        nohup podman system service --time=0 "unix://${sock}" &> /dev/null &
        for _ in $(seq 10); do
            [[ -S ${sock} ]] && break
            sleep 1
        done
    fi
    if [[ ! -S ${sock} ]]; then
        echo "ERROR: podman API socket ${sock} is not available"
        exit 1
    fi
    export DOCKER_HOST=unix://${sock}
fi

# prefer docker compose, else podman compose
if docker compose version &> /dev/null; then
    compose="docker compose"
elif podman compose version &> /dev/null; then
    compose="podman compose"
else
    echo "ERROR: neither 'docker compose' nor 'podman compose' is available"
    exit 1
fi
compose="${compose} -f compose-phone.yaml"

if [[ "$1" == "stop" ]]; then
    ${compose} down
    exit 0
fi

# release binaries of bobview are only published for aarch64 (the phone), so
# other architectures must build it from source
bobview_install() {
    if [[ $(uname -m) == aarch64 ]]; then
        echo "Install it with:"
        echo "  sudo apt install libxkbcommon0 libwayland-client0 libegl1 libgl1-mesa-dri"
        echo "  curl -sSfL https://raw.githubusercontent.com/gilesknap/bobview/main/install.sh | bash"
    else
        echo "There is no $(uname -m) release of bobview (install.sh only provides"
        echo "aarch64), so build it from source with a Rust toolchain (https://rustup.rs):"
        echo "  cargo install --locked --git https://github.com/gilesknap/bobview bobview"
        echo "This installs into ~/.cargo/bin, make sure that is on your PATH."
    fi
}

if ! command -v bobview &> /dev/null; then
    echo "ERROR: bobview not found on PATH."
    bobview_install
    exit 1
fi

# exit status 126 means the binary cannot be executed, e.g. the aarch64
# release installed on an x86_64 machine
bobview --help &> /dev/null && rc=0 || rc=$?
if [[ ${rc} == 126 ]]; then
    echo "ERROR: $(command -v bobview) cannot run on this $(uname -m) machine"
    echo "(probably the aarch64 release). Remove it, then:"
    bobview_install
    exit 1
fi

${compose} up -d

# the IOCs write their auto-generated screens at startup and demo.bob links
# to them, so give them a moment to appear
for ioc in bl01t-di-cam-01 bl01t-mo-sim-01; do
    for _ in $(seq 30); do
        [[ -n "$(ls -A opi/auto-generated/${ioc} 2> /dev/null)" ]] && break
        sleep 1
    done
done

# each IOC has its own CA and PVA ports on the host network (see
# compose-phone.yaml), so point the clients straight at them
export EPICS_CA_AUTO_ADDR_LIST=NO
export EPICS_CA_ADDR_LIST="127.0.0.1:5064 127.0.0.1:6064"
export EPICS_PVA_AUTO_ADDR_LIST=NO
export EPICS_PVA_NAME_SERVERS="127.0.0.1:5075 127.0.0.1:6075"

exec bobview opi/demo.bob
