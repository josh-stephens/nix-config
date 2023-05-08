#!/usr/bin/env bash
#
# Helps synthesize TTS and play it.
set -ex

CACHE_DIR="${HOME}/Games/FFXIV/TTS"
mkdir -p "${CACHE_DIR}"

text="$1"
filename="$(echo "${text}" | base64 -).wav"
path="${CACHE_DIR}/${filename}"

if [ -f "${path}" ]; then
  play "${path}"
  exit 0
fi

tts --text "${text}" --out_path="${path}"
play "${path}"
exit 0
