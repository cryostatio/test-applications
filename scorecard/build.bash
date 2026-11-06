#!/usr/bin/env bash
# Copyright The Cryostat Authors.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DIR="$(dirname "$(readlink -f "$0")")"
BUILD_IMG="${APP_IMAGE:-${APP_REGISTRY:-quay.io}/${APP_NAMESPACE:-redhat-java-monitoring}/${APP_NAME:-cryostat-operator-scorecard-app}:${APP_VERSION:-${BUILD_TAG:-latest}}}"
BUILD_REPO="${BUILD_IMG%:*}"
BUILD_TARGET="${BUILD_TARGET:-application}"
agent_version="${CRYOSTAT_AGENT_VERSION:-latest}"
AGENT_INIT_IMG="${AGENT_INIT_IMG:-quay.io/cryostat/cryostat-agent-init:${agent_version,,}}"
read -r -a architectures <<< "${ARCHS:-amd64 arm64}"
platforms=()
for arch in "${architectures[@]}"; do
    platforms+=("linux/${arch}")
done
PLATFORMS="$(IFS=,; echo "${platforms[*]}")"

# Replace the local manifest so rebuilding with fewer architectures drops stale entries.
if podman manifest exists "${BUILD_IMG}"; then
    podman manifest rm "${BUILD_IMG}"
fi
podman build --pull=missing --target "${BUILD_TARGET}" \
    --manifest "${BUILD_IMG}" --platform "${PLATFORMS}" \
    --build-arg AGENT_INIT_IMG="${AGENT_INIT_IMG}" \
    -f "${DIR}/Containerfile" "${DIR}"

for tag in ${TAGS:-}; do
    if [ "${BUILD_IMG}" != "${BUILD_REPO}:${tag}" ]; then
        podman tag "${BUILD_IMG}" "${BUILD_REPO}:${tag}"
    fi
done

if [ "${PUSH_MANIFEST:-false}" = "true" ]; then
    podman manifest push --all "${BUILD_IMG}" "docker://${BUILD_IMG}"
    for tag in ${TAGS:-}; do
        if [ "${BUILD_IMG}" != "${BUILD_REPO}:${tag}" ]; then
            podman manifest push --all "${BUILD_REPO}:${tag}" "docker://${BUILD_REPO}:${tag}"
        fi
    done
fi
