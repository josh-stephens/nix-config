#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE
export WINEDLLOVERRIDES="d3dcompiler_47=n;dxgi=n,b"

rm -f "${HOME}/.xlcore/wineprefix/drive_c/users/$(whoami)/AppData/Local/NUCefSharp/pid.txt"
gamemoderun XIVLauncher.Core
