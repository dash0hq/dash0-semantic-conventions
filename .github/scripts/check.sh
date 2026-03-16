#!/usr/bin/env bash
# Validate the registry model.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${SCRIPT_DIR}/../.." && pwd)"
weaver_image="$(cat "${SCRIPT_DIR}/../weaver.image")"

docker run --rm \
  -v "${project_root}/model:/model" \
  "$weaver_image" \
  registry check -r /model
