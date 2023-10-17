#!/bin/sh

cd "$(dirname "$0")"

. ./container.conf

docker build ../container-src/ -t ${CONTAINER_NAME}:${CONTAINER_TAG}
