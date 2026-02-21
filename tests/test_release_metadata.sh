#!/usr/bin/env bash
set -euo pipefail

release_json="release.json"
module_json="src/module.json"
workflow_file=".github/workflows/release.yml"

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required to run this test" >&2
  exit 1
fi

if [ ! -f "$release_json" ]; then
  echo "FAIL: Missing $release_json" >&2
  exit 1
fi

if [ ! -f "$module_json" ]; then
  echo "FAIL: Missing $module_json" >&2
  exit 1
fi

if [ ! -f "$workflow_file" ]; then
  echo "FAIL: Missing $workflow_file" >&2
  exit 1
fi

version=$(jq -r '.version' "$release_json")
module_version=$(jq -r '.version' "$module_json")
expected_url="https://github.com/charlesvestal/move-anything-airplay/releases/download/v${version}/airplay-module.tar.gz"
url=$(jq -r '.download_url' "$release_json")

if [ -z "$version" ] || [ "$version" = "null" ]; then
  echo "FAIL: release.json missing version" >&2
  exit 1
fi

if [ "$module_version" != "$version" ]; then
  echo "FAIL: version mismatch: src/module.json=$module_version release.json=$version" >&2
  exit 1
fi

if [ "$url" != "$expected_url" ]; then
  echo "FAIL: release.json download_url mismatch: got=$url expected=$expected_url" >&2
  exit 1
fi

if ! rg -q "Verify release\.json metadata" "$workflow_file"; then
  echo "FAIL: release workflow missing release.json verification step" >&2
  exit 1
fi

echo "PASS: release metadata is present and release workflow validates it"
exit 0
