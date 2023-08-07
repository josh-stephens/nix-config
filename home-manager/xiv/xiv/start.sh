#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE
export WINEDLLOVERRIDES="d3dcompiler_47=n;dxgi=n,b"

nohup TotallyNotCef 'https://quisquous.github.io/cactbot/ui/raidboss/raidboss.html?OVERLAY_WS=ws://127.0.0.1:10501/ws' 18283 1 1 & disown
gamescope -w 1920 -h 1080 -W 1920 -H 1080 -f -b --expose-wayland --force-windows-fullscreen -- gamemoderun XIVLauncher.Core
