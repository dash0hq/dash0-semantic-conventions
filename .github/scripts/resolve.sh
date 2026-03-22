#!/usr/bin/env bash
# Resolve the full registry (including OTel dependencies).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${SCRIPT_DIR}/../.." && pwd)"
weaver_image="$(cat "${SCRIPT_DIR}/../weaver.image")"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -v "${project_root}/model:/model" \
  -v "${project_root}:/out" \
  "$weaver_image" \
  registry resolve -r /model -o /out/resolved.json
