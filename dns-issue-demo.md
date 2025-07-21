# DNS Issue Demonstration

## intro

This branch of [example-services](https://github.com/epics-containers/example-services/dns-tests) demonstrates the DNS issue with channel access discussed here <https://github.com/epics-base/epics-base/issues/488>.

## Problem

The problem is that channel access clients will resolve DNS names in the `EPICS_CA_ADDR_LIST` environment variable, but only on first connection. If the connection is lost, the client will not re-resolve the DNS names, and will continue to use the original IP addresses.

This can be problem in a dynamic environment where IP addresses change, such as when using Kubernetes or other container orchestration systems.

## How to reproduce

### setup the environment

```bash
git clone https://github.com/epics-containers/example-services.git -b dns-tests
cd example-services
source ./environment.sh
docker compose up -d
```

This will start up the example beamline with a ca-gateway, a simulation detector and simulation motor IOC, and a phoebus client.

You can see the detector PVs in the phoebus client, and you can use `camonitor` to read the values from the command line. (that is if you have `camonitor` installed locally, otherwise you can use the `docker compose ca-gateway exec bash` command to get a shell in the ca-gateway container, then run `camonitor` inside the ca-gateway container).

```bash
camonitor BL01T-DI-CAM-01:DET:ArrayCounter_RBV
```

### verify IOC restart does not break channel access

```bash
docker compose down bl01t-di-cam-01
# camonitor should now stop
docker compose up -d bl01t-di-cam-01
# camonitor should now start again after a few seconds
```

You will need to wait a few seconds for the IOC to restart then you can right click -> 'Reload Display' in the phoebus client to see the PV values restored.

### demonstrate changing the IP address

Now go and edit the `services/bl01t-di-cam-01/compose.yml` file and change the `ipv4_address` of the `channel_access` network to a different value, e.g. `170.200.0.80`.

Now repeat the above steps, restarting the IOC. You will find that channel access clients will not be able to connect to the IOC, because the gateway is still using the old IP address for bl01t-di-cam-01.

Finally change back the `ipv4_address` to the original value, e.g. and restart the IOC again. You will find that the channel access clients can connect again without any issues.


## Diagnostics tools

It is useful to have the dnstools running inside the container network to demonstrate that DNS is operating as expected. The following will demo that the name `bl01t-di-cam-01` resolves to the expected IP address.

```bash
docker compose exec ca-gateway bash
apt update && apt install -y dnsutils
nslookup bl01t-di-cam-01
```


## Tidy up

When you are done, you can stop all the containers with:

```bash
docker compose down
```
