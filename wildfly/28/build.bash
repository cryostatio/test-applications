#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    rm -rf "${DIR}/cache"
    popd
}
trap cleanup EXIT

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-wildfly-28-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-latest}"
CRYOSTAT_AGENT_VERSION="${CRYOSTAT_AGENT_VERSION:-0.6.0-SNAPSHOT}"
IFS=', ' read -r -a ARCHS <<< "${IMAGE_ARCHS:-amd64 arm64}"

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

for arch in "${ARCHS[@]}"; do
    echo "Building for ${arch} ..."
    podman build --pull=missing --build-arg agent_version="${CRYOSTAT_AGENT_VERSION,,}" --platform="linux/${arch}" -t "${BUILD_IMG}:linux-${arch}" -f "${DIR}/Containerfile" "${DIR}"
    podman manifest add "${BUILD_IMG}:${BUILD_TAG}" containers-storage:"${BUILD_IMG}:linux-${arch}"
done

for tag in ${TAGS}; do
    podman tag "${BUILD_IMG}:${BUILD_TAG}" "${BUILD_IMG}:${tag}"
done

if [ "${PUSH_MANIFEST}" = "true" ]; then
    for tag in ${TAGS}; do
        podman manifest push "${BUILD_IMG}:${tag}" "docker://${BUILD_IMG}:${tag}"
    done
fi
