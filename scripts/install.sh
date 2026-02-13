#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODULE_ID="airplay"
DEVICE_HOST="${DEVICE_HOST:-move.local}"
REMOTE_BASE="/data/UserData/move-anything/modules/sound_generators"
REMOTE_DIR="$REMOTE_BASE/$MODULE_ID"
DIST_DIR="$REPO_ROOT/dist/$MODULE_ID"

if [ ! -d "$DIST_DIR" ]; then
  echo "Error: $DIST_DIR not found. Run ./scripts/build.sh first."
  exit 1
fi

echo "=== Installing AirPlay Module ==="
echo "Device: $DEVICE_HOST"
echo "Remote: $REMOTE_DIR"
echo ""

ssh "root@$DEVICE_HOST" "mkdir -p $REMOTE_DIR"
scp -r "$DIST_DIR/"* "root@$DEVICE_HOST:$REMOTE_DIR/"
ssh "root@$DEVICE_HOST" "chown -R ableton:users $REMOTE_DIR"

echo ""
echo "=== Install Complete ==="
echo "Module installed to $REMOTE_DIR"
