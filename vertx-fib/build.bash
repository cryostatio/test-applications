#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

sh "${DIR}/gradlew" -p "${DIR}" compileJava > /dev/null 2>&1 # initialize gradle plugins etc. before trying to parse project version

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-vertx-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-$(sh "${DIR}/gradlew" -p "${DIR}" -q printVersion)}"

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

for arch in amd64 arm64; do
    echo "Building for ${arch} ..."
    JIB_ARCH="${arch}" sh "${DIR}/gradlew" -p "${DIR}" jibDockerBuild
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
