#!/bin/bash

CLUSTER_DOMAIN=bobbins.io

docker network create --driver=overlay traefik

docker service create \
   --name docker-proxy \
   --network traefik \
   --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
   --constraint 'node.role==manager' \
   rancher/socat-docker

docker service create \
    --name traefik \
    --publish 80:80 \
    --publish 443:443 \
    --publish 8080:8080 \
    --network traefik \
    --secret traefik.crt \
    --secret traefik.key \
    --mode global \
    traefik:latest \
    --docker \
    --docker.swarmmode \
    --docker.endpoint=tcp://docker-proxy:2375 \
    --docker.domain=${CLUSTER_DOMAIN} \
    --docker.watch \
    --entryPoints='Name:http Address::80 Redirect.EntryPoint:https' \
    --entryPoints='Name:https Address::443 TLS:/run/secrets/traefik.crt,/run/secrets/traefik.key' \
    --defaultEntryPoints='http,https' \
    --web

    #--entryPoints='Name:http Address::80 Redirect.EntryPoint:https' \
