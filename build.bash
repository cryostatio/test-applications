#!/usr/bin/env bash

set -xe

files="$(find . -mindepth 2 -type f -name build.bash)"
for p in ${files}; do
    PUSH_MANIFEST="${PUSH_MANIFEST:-false}" TAGS="$(echo "${TAGS:-latest}" | tr '[:upper:]' '[:lower:]')" bash "${p}"
done
