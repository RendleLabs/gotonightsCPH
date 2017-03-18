#!/bin/bash

docker network create --driver=overlay dockerproxy

docker service create \
    --name docker-proxy \
    --network dockerproxy \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
    --constraint 'node.role==manager' \
    rancher/socat-docker

docker service create \
    --name traefik \
    --publish 80:80 --publish 8080:8080 \
    --network dockerproxy \
    --network scientiams \
    --mode global \
    traefik:latest \
    --docker \
    --docker.swarmmode \
    --docker.endpoint=tcp://docker-proxy:2375 \
    --docker.domain=scientiadev.com \
    --docker.watch \
    --web
