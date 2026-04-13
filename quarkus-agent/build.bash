#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

pushd "${DIR}"
function cleanup() {
    popd
}
trap cleanup EXIT

BUILD_IMG="${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-quarkus-cryostat-agent}"
BUILD_TAG="${APP_VERSION:-$(mvn -f "${DIR}/pom.xml" help:evaluate -B -q -DforceStdout -Dexpression=project.version)}"

"${DIR}/mvnw" -B -U -DskipTests -Dio.cryostat.agent.version="${CRYOSTAT_AGENT_VERSION}" clean package

podman manifest create "${BUILD_IMG}:${BUILD_TAG}"

function prepareAsyncProfiler() {
    ASYNC_PROFILER="${DIR}/src/main/docker/extras/async-profiler"
    mkdir -p "${ASYNC_PROFILER}"
    if [ ! -f "${ASYNC_PROFILER}/async-profiler.jar" ]; then
        rm -f "${ASYNC_PROFILER}/async-profiler.jar"
    fi
    if [ ! -f "${ASYNC_PROFILER}/libasyncProfiler.so" ] ; then
        rm -f "${ASYNC_PROFILER}/libasyncProfiler.so"
    fi
    ASYNC_PROFILER_TAG="$(gh -R async-profiler/async-profiler release list --exclude-drafts --exclude-pre-releases --limit 1 --json tagName --jq '.[0].tagName')"
    ASYNC_PROFILER_VERSION="${ASYNC_PROFILER_TAG:1}"
    ASYNC_PROFILER_ARCH="x64"
    if [ "$1" = "amd64" ]; then
        ASYNC_PROFILER_ARCH="x64"
    else
        ASYNC_PROFILER_ARCH="$1"
    fi
    ASYNC_PROFILER_ARCHIVE="async-profiler-${ASYNC_PROFILER_VERSION}-linux-${ASYNC_PROFILER_ARCH}"
    gh -R async-profiler/async-profiler release download --dir "${ASYNC_PROFILER}" --clobber "${ASYNC_PROFILER_TAG}" -p async-profiler.jar
    gh -R async-profiler/async-profiler release download --clobber "${ASYNC_PROFILER_TAG}" -p "${ASYNC_PROFILER_ARCHIVE}.tar.gz"
    tar xzvf "${ASYNC_PROFILER_ARCHIVE}.tar.gz"
    mv "${ASYNC_PROFILER_ARCHIVE}/lib/libasyncProfiler.so" "${ASYNC_PROFILER}"
    rm -rf "${ASYNC_PROFILER_ARCHIVE}" "${ASYNC_PROFILER_ARCHIVE}.tar.gz"
}

for arch in ${ARCHS:-amd64 arm64}; do
    prepareAsyncProfiler "${arch}"
    echo "Building for ${arch} ..."
    podman build --pull=missing --platform="linux/${arch}" -t "${BUILD_IMG}:linux-${arch}" -f "${DIR}/src/main/docker/Dockerfile.jvm" "${DIR}"
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
