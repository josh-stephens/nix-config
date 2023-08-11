#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE
export WINEDLLOVERRIDES="d3dcompiler_47=n;dxgi=n,b"
export TZ="America/Los_Angeles"

systemctl --user start TotallyNotCef.service
gamemoderun XIVLauncher.Core
