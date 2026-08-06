#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright 2026 Dash0 Inc.
#
# Generate the semantic conventions documentation.
# Works both locally (via Docker) and in CI (with Weaver installed).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
_OUTPUT_ARG="${1:-${REPO_ROOT}/docs}"
OUTPUT_DIR="$(cd "${_OUTPUT_ARG}" 2>/dev/null && pwd || { mkdir -p "${_OUTPUT_ARG}" && cd "${_OUTPUT_ARG}" && pwd; })"
TEMPLATE_TARGET="${2:-markdown}"

if command -v weaver &>/dev/null; then
  echo "Using local Weaver installation"
  weaver registry generate \
    --registry="${REPO_ROOT}/model" \
    --templates="${REPO_ROOT}/templates" \
    "${TEMPLATE_TARGET}" \
    "${OUTPUT_DIR}"
else
  echo "Weaver not found, using Docker"
  docker run --rm \
    -v "${REPO_ROOT}/model:/model" \
    -v "${REPO_ROOT}/templates:/templates" \
    -v "${OUTPUT_DIR}:/docs" \
    otel/weaver:latest \
    registry generate \
    --registry=/model \
    --templates=/templates \
    "${TEMPLATE_TARGET}" \
    /docs/
fi

echo "Documentation generated in ${OUTPUT_DIR}"
