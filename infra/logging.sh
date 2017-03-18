#!/bin/bash

docker service create \
  --network infra \
  --name elasticsearch \
  elasticsearch

docker service create \
  --network traefik \
  --network infra \
  --label traefik.port=5601 \
  --label traefik.docker.network=traefik \
  --publish 5601:5601 \
  --name kibana \
  -e ELASTICSEARCH_URL=http://elasticsearch:9200 \
  kibana