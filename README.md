# Move Anything - AirPlay Receiver

An AirPlay audio receiver module for [Move Anything](https://github.com/charlesvestal/move-anything) on Ableton Move hardware. Stream audio from your iPhone, iPad, or Mac directly to Move's signal chain.

## Features

- AirPlay 1 receiver using [shairport-sync](https://github.com/mikebrady/shairport-sync) (cross-compiled and bundled)
- Broadcasts as "Move - Slot N" on the network (slot number auto-assigned)
- Chainable sound generator — works in the Signal Chain with audio FX
- Gain control exposed to Shadow UI knobs
- Zero device-side dependencies beyond what Move Anything provides (avahi, OpenSSL)

## Requirements

- Move Anything host (v0.3.0+)
- avahi-daemon running on the device (standard on Move)
- WiFi network shared between Move and the AirPlay source device

## Build

```bash
./scripts/build.sh
```

Builds via Docker. Cross-compiles both shairport-sync (ARM64) and the DSP plugin. Output: `dist/airplay-module.tar.gz`.

## Install

```bash
./scripts/install.sh
```

Deploys to `/data/UserData/move-anything/modules/sound_generators/airplay/` on the device.

## Usage

1. Load the AirPlay module in a Signal Chain slot
2. On your iPhone/iPad/Mac, open AirPlay output picker
3. Select "Move - Slot 1" (or the appropriate slot number)
4. Audio streams through the chain — add audio FX, adjust gain, etc.

## Architecture

The DSP plugin (`airplay_plugin.c`) follows the same pattern as the Webstream module:

1. Creates a named FIFO at `/tmp/airplay-audio-<pid>`
2. Generates a shairport-sync config and spawns it with the `pipe` backend
3. shairport-sync registers via avahi mDNS, receives AirPlay audio, decodes ALAC, writes raw S16LE stereo 44100Hz PCM to the FIFO
4. `render_block` reads from the FIFO into a ring buffer and outputs audio

Bundled shared libraries (`lib/`) provide libconfig and libavahi-client for devices that don't have them.

## License

MIT
