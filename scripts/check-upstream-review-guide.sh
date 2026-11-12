#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright 2026 Dash0 Inc.
#
# List upstream changes to the OpenTelemetry model review instructions that
# model/.cursor/BUGBOT.md has not picked up yet. Requires the GitHub CLI.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES_FILE="${REPO_ROOT}/model/.cursor/BUGBOT.md"
UPSTREAM_REPO="open-telemetry/semantic-conventions"
UPSTREAM_PATH=".github/instructions/model-yaml.instructions.md"

pinned="$(grep -oE "${UPSTREAM_REPO}/blob/[0-9a-f]{40}/${UPSTREAM_PATH}" "${RULES_FILE}" | head -n 1 | cut -d/ -f4)"
if [[ -z "${pinned}" ]]; then
  echo "No pinned upstream commit found in ${RULES_FILE}" >&2
  exit 1
fi

latest="$(gh api "repos/${UPSTREAM_REPO}/commits?path=${UPSTREAM_PATH}&per_page=1" --jq '.[0].sha')"
if [[ "${latest}" == "${pinned}" ]]; then
  echo "Up to date with ${UPSTREAM_REPO}@${pinned:0:7}."
  exit 0
fi

echo "Upstream changed since ${pinned:0:7}; latest is ${latest:0:7}:"
gh api "repos/${UPSTREAM_REPO}/commits?path=${UPSTREAM_PATH}&per_page=20" \
  --jq ".[] | select(.sha != \"${pinned}\") | \"  \(.sha[0:7]) \(.commit.message | split(\"\n\")[0])\""
echo
echo "Diff: https://github.com/${UPSTREAM_REPO}/compare/${pinned}...${latest}"
exit 1
