#!/bin/bash
export DOCKER_HOST=tcp://$(terraform output manager_fqdn):2376
export DOCKER_TLS_VERIFY=1
