#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    popd
}
trap cleanup EXIT

"${DIR}/mvnw" -DskipTests clean package
podman build -t quay.io/redhat-java-monitoring/quarkus-cryostat-agent:latest -f "${DIR}/src/main/docker/Dockerfile.jvm" "${DIR}"
podman image prune -f
