#!/usr/bin/env sh

LABEL=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk 'NR==13 {first = $1; $1=""; print $0}' | sed 's/^ //g')

sketchybar --set "${NAME}" label="${LABEL}"
