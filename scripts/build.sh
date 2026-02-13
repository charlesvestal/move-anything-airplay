#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="move-anything-airplay-builder"
OUTPUT_BASENAME="${OUTPUT_BASENAME:-airplay-module}"

if [ -z "${CROSS_PREFIX:-}" ] && [ ! -f "/.dockerenv" ]; then
  echo "=== AirPlay Module Build (via Docker) ==="
  if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"
  fi
  docker run --rm \
    -v "$REPO_ROOT:/build" \
    -u "$(id -u):$(id -g)" \
    -w /build \
    -e OUTPUT_BASENAME="$OUTPUT_BASENAME" \
    "$IMAGE_NAME" \
    ./scripts/build.sh
  exit 0
fi

CROSS_PREFIX="${CROSS_PREFIX:-aarch64-linux-gnu-}"

cd "$REPO_ROOT"
rm -rf build/module dist/airplay
mkdir -p build/module dist/airplay dist/airplay/bin

# --- Build shairport-sync ---
SHAIRPORT_TAG="4.3.5"

if [ ! -f "build/shairport-sync/shairport-sync" ]; then
  echo "Building shairport-sync ${SHAIRPORT_TAG}..."
  rm -rf build/shairport-sync
  git clone --depth 1 --branch "${SHAIRPORT_TAG}" \
    https://github.com/mikebrady/shairport-sync.git build/shairport-sync

  cd build/shairport-sync
  autoreconf -fi

  ./configure \
    --host=aarch64-linux-gnu \
    --with-pipe \
    --with-avahi \
    --with-ssl=openssl \
    --without-alsa \
    CC="${CROSS_PREFIX}gcc" \
    CXX="${CROSS_PREFIX}g++"

  make -j"$(nproc)"
  cd "$REPO_ROOT"
  echo "shairport-sync built successfully"
else
  echo "Using cached shairport-sync build"
fi

cat build/shairport-sync/shairport-sync > dist/airplay/bin/shairport-sync
chmod +x dist/airplay/bin/shairport-sync

# Bundle shared libraries that may not be on the device
echo "Bundling shared libraries..."
mkdir -p dist/airplay/lib
for lib in libconfig.so.9 libpopt.so.0 libavahi-client.so.3; do
  src="/usr/lib/aarch64-linux-gnu/${lib}"
  if [ -L "$src" ]; then
    real="$(readlink -f "$src")"
    cat "$real" > "dist/airplay/lib/$(basename "$real")"
    ln -sf "$(basename "$real")" "dist/airplay/lib/${lib}"
  elif [ -f "$src" ]; then
    cat "$src" > "dist/airplay/lib/${lib}"
  fi
done

# --- Build DSP plugin ---
echo "Compiling v2 DSP plugin..."
"${CROSS_PREFIX}gcc" -O3 -g -shared -fPIC \
  src/dsp/airplay_plugin.c \
  -o build/module/dsp.so \
  -Isrc/dsp \
  -lpthread -lm

cat src/module.json > dist/airplay/module.json
cat src/ui.js > dist/airplay/ui.js
cat src/ui_chain.js > dist/airplay/ui_chain.js
cat build/module/dsp.so > dist/airplay/dsp.so
chmod +x dist/airplay/dsp.so

# --- Package ---
(
  cd dist
  tar -czvf "${OUTPUT_BASENAME}.tar.gz" airplay/
)

echo "=== Build Complete ==="
echo "Module dir: dist/airplay"
echo "Tarball: dist/${OUTPUT_BASENAME}.tar.gz"
