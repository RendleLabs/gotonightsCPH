#!/bin/bash
export DOCKER_HOST=tcp://$1:2376
export DOCKER_TLS_VERIFY=1
unset DOCKER_CERT_PATH
docker swarm join-token -q worker >./swarm.token
