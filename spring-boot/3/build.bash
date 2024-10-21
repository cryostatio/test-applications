#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

sh "${DIR}/gradlew" -p "${DIR}" compileJava > /dev/null 2>&1 # initialize gradle plugins etc. before trying to parse project version

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-spring-boot-3-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-$(sh "${DIR}/gradlew" -p "${DIR}" -q printVersion)}"

"${DIR}/gradlew" -p "${DIR}" clean build

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

for arch in ${ARCHS:-amd64 arm64}; do
    echo "Building for ${arch} ..."
    podman build --build-arg agent_version="${CRYOSTAT_AGENT_VERSION,,}" --platform="linux/${arch}" -t "${BUILD_IMG}:linux-${arch}" -f "${DIR}/Containerfile" "${DIR}"
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
