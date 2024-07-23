#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    rm -rf "${DIR}/cache"
    popd
}
trap cleanup EXIT

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-gameserver-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-latest}"
CRYOSTAT_AGENT_VERSION="${CRYOSTAT_AGENT_VERSION:-0.5.0-SNAPSHOT}"
IFS=', ' read -r -a ARCHS <<< "${IMAGE_ARCHS:-amd64 arm64}"
IFS=', ' read -r -a JDKS <<< "${JDK_VERSIONS:-11 17 21}"

for jdk in "${JDKS[@]}"; do
    podman manifest create "${BUILD_IMG}:${BUILD_TAG}-jdk${jdk}"
done

for arch in "${ARCHS[@]}"; do
  for jdk in "${JDKS[@]}"; do
    echo "Building JDK ${jdk} for ${arch} ..."
    podman build --build-arg server_img="docker.io/itzg/minecraft-server:java${jdk}-jdk" --build-arg agent_version="${CRYOSTAT_AGENT_VERSION,,}" --platform="linux/${arch}" -t "${BUILD_IMG}:linux-${arch}-jdk${jdk}" -f "${DIR}/Containerfile" "${DIR}"
    podman manifest add "${BUILD_IMG}:${BUILD_TAG}-jdk${jdk}" containers-storage:"${BUILD_IMG}:linux-${arch}-jdk${jdk}"
  done
done

for tag in ${TAGS}; do
    for jdk in "${JDKS[@]}"; do
        podman tag "${BUILD_IMG}:${BUILD_TAG}-jdk${jdk}" "${BUILD_IMG}:${tag}-jdk${jdk}"
    done
done

if [ "${PUSH_MANIFEST}" = "true" ]; then
    for tag in ${TAGS}; do
        for jdk in "${JDKS[@]}"; do
            podman manifest push "${BUILD_IMG}:${tag}-jdk${jdk}" "docker://${BUILD_IMG}:${tag}-jdk${jdk}"
        done
    done
fi
