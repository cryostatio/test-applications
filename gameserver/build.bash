#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    popd
}
trap cleanup EXIT

podman build -t quay.io/redhat-java-monitoring/gameserver-cryostat-agent:latest -f "${DIR}/Containerfile" "${DIR}"
