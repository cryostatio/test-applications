#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    popd
}
trap cleanup EXIT

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-gameserver-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-latest}"

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

for arch in amd64 arm64; do
    echo "Building for ${arch} ..."
    podman build -t "quay.io/redhat-java-monitoring/gameserver-cryostat-agent:linux-${arch}" -f "${DIR}/Containerfile" "${DIR}"
    podman manifest add "${BUILD_IMG}:${BUILD_TAG}" containers-storage:"${BUILD_IMG}:linux-${arch}"
done

podman tag "${BUILD_IMG}:${BUILD_TAG}" "${BUILD_IMG}:latest"
