#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    popd
}
trap cleanup EXIT

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-quarkus-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-$(mvn -f "${DIR}/pom.xml" help:evaluate -o -B -q -DforceStdout -Dexpression=project.version)}"

"${DIR}/mvnw" -DskipTests clean package

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

for arch in amd64 arm64; do
    echo "Building for ${arch} ..."
    podman build --platform="linux/${arch}" -t "${BUILD_IMG}:linux-${arch}" -f "${DIR}/src/main/docker/Dockerfile.jvm" "${DIR}"
    podman manifest add "${BUILD_IMG}:${BUILD_TAG}" containers-storage:"${BUILD_IMG}:linux-${arch}"
done

for tag in ${TAGS}; do
    podman tag "${BUILD_IMG}:${BUILD_TAG}" "${BUILD_IMG}:${tag}"
done

if [ "${PUSH_MANIFEST}" = "true" ]; then
    podman manifest push "${BUILD_IMG}:${BUILD_TAG}"
fi
