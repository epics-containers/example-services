#!/bin/bash

root=$(realpath $(dirname $0)/..)

echo "setting up configuration file for pva gateway"

cat $root/services/pvagw/config/pvagw.template |
  sed -e "s/172.20.255.255/$CA_BROADCAST/g" \
      -e "s/5075/$EPICS_PVA_SERVER_PORT/g" > \
      $root/services/pvagw/config/pvagw.config

echo "setting up configuration file for phoebus"

cat $root/services/phoebus/config/settings.template |
  sed -e "s/5064/$EPICS_CA_SERVER_PORT/g" \
      -e "s/5065/$EPICS_CA_REPEATER_PORT/g" \
      -e "s/5075/$EPICS_PVA_SERVER_PORT/g" > \
      $root/services/phoebus/config/settings.ini

# this is a workaround for docker creating host mounts as root if they don't exist:
# not required for podman but benign
for ioc in bl01t-di-cam-01 bl01t-ea-test-01 bl01t-mo-sim-01; do
  mkdir -p $root/autosave/$ioc
  mkdir -p $root/runtime/$ioc
  mkdir -p $root/opi/auto-generated/$ioc
done
