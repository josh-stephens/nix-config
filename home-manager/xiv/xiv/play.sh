#!/usr/bin/env bash
#
# Helps synthesize TTS and play it.
set -ex

CACHE_DIR="${HOME}/Games/FFXIV/TTS"
LOG="${HOME}/Games/FFXIV/TTS/say.log"
mkdir -p "${CACHE_DIR}"

text="$(echo "${1}" | awk '{print tolower($0)}' | tr -d '[:punct:]')"
filename="$(echo "${text}" | base64 -).wav"
path="${CACHE_DIR}/${filename}"

echo "${BASH_SOURCE[0]}: ${text}: ${path}" >> $LOG

if [ -f "${path}" ]; then
  play "${path}"
  exit 0
fi

tts --text "${text}" --out_path="${path}"
play "${path}"
exit 0
