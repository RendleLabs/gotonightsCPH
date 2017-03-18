#!/bin/bash

docker service create \
  --name influxdb \
  --network infra \
  influxdb

docker service create \
  --name grafana \
  --network traefik \
  --network infra \
  --publish 3000:3000 \
  --label traefik.port=3000 \
  --label traefik.docker.network=traefik \
  -e GF_SERVER_ROOT_URL=https://grafana.bobbins.io \
  grafana/grafana