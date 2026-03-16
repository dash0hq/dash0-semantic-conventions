#!/usr/bin/env bash
# Run Weaver live-check tests against JSON test payloads.
#
# Usage:
#   run-live-check-tests.sh <valid|invalid>
#
# The argument selects the test suite (valid or invalid).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${SCRIPT_DIR}/../.." && pwd)"
weaver_image="$(cat "${SCRIPT_DIR}/../weaver.image")"

suite="${1:?Usage: $0 <valid|invalid>}"

if [[ "$suite" != "valid" && "$suite" != "invalid" ]]; then
  echo "ERROR: first argument must be 'valid' or 'invalid', got '$suite'" >&2
  exit 2
fi

test_dir="${project_root}/tests/${suite}"
failed=0
count=0

for file in $(find "$test_dir" -name '*.json' | sort); do
  count=$((count + 1))
  rel_path="${file#"$project_root"/}"
  echo "--- ${rel_path} ---"

  if docker run --rm \
      -v "${project_root}/model:/model" \
      -v "${file}:/test.json" \
      "$weaver_image" \
      registry live-check -r /model --input-source /test.json --input-format json --no-stream; then
    if [[ "$suite" == "valid" ]]; then
      echo "PASS: ${rel_path}"
    else
      echo "FAIL: ${rel_path} (should fail but passed)"
      failed=1
    fi
  else
    if [[ "$suite" == "invalid" ]]; then
      echo "PASS: ${rel_path} (correctly rejected)"
    else
      echo "FAIL: ${rel_path} (should pass but didn't)"
      failed=1
    fi
  fi
done

if [[ "$count" -eq 0 ]]; then
  echo "ERROR: no ${suite} test files found"
  exit 1
fi

exit $failed
