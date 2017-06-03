#!/bin/bash

set -o pipefail

IMAGE=varenikx/chrome-bdd
VERSION=latest

docker build -t ${IMAGE}:${VERSION} . | tee build.log || exit 1
ID=$(tail -1 build.log | awk '{print $3;}')
docker tag $ID ${IMAGE}:latest

docker images | grep ${IMAGE}
