#!/usr/bin/env bash
export XL_SECRET_PROVIDER=FILE

XIVLauncher.Core
hudkit "${XDG_CONFIG_HOME}/xiv/ember.json"
hudkit "${XDG_CONFIG_HOME}/xiv/cactbot-timelines.json"
hudkit "${XDG_CONFIG_HOME}/xiv/cactbot-alerts.json"
hudkit "${XDG_CONFIG_HOME}/xiv/cactbot-oopsyraidsy.json"
