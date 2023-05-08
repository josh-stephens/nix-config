#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE

rm -f "${HOME}/.xlcore/wineprefix/drive_c/users/$(whoami)/AppData/Local/NUCefSharp/pid.txt"
XIVLauncher.Core
