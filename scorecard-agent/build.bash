#!/usr/bin/env bash
# Copyright The Cryostat Authors.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DIR="$(dirname "$(readlink -f "$0")")"
APP_NAME="${APP_NAME:-cryostat-operator-scorecard-agent-app}" \
BUILD_TARGET=bundled-agent \
    bash "${DIR}/../scorecard/build.bash"
