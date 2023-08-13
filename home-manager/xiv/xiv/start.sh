#!/usr/bin/env bash

nohup wget --wait=4 "http://127.0.0.1:4646/ffxivlauncher/$(op item get "Square Enix" --otp)" &

systemctl --user start TotallyNotCef.service
gamemoderun XIVLauncher.Core
