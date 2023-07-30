#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE
export WINEDLLOVERRIDES="d3dcompiler_47=n;dxgi=n,b"

rm -f "${HOME}/.xlcore/wineprefix/drive_c/users/$(whoami)/AppData/Local/NUCefSharp/pid.txt"
nohup TotallyNotCef 'https://quisquous.github.io/cactbot/ui/raidboss/raidboss.html?OVERLAY_WS=ws://127.0.0.1:10501/ws' 8080 1 1 & disown
gamemoderun XIVLauncher.Core
