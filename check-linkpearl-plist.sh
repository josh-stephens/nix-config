#!/bin/bash
# Check the actual linkpearl plist

echo "=== Plist contents ==="
cat ~/Library/LaunchAgents/org.nix-community.home.linkpearl.plist

echo -e "\n=== Checking service status ==="
launchctl list | grep linkpearl

echo -e "\n=== Checking service details ==="
launchctl print gui/$(id -u)/org.nix-community.home.linkpearl 2>&1

echo -e "\n=== Loading service ==="
launchctl bootout gui/$(id -u)/org.nix-community.home.linkpearl 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.linkpearl.plist

echo -e "\n=== Checking logs ==="
echo "stdout:"
cat /tmp/linkpearl.out 2>/dev/null | tail -20
echo -e "\nstderr:"
cat /tmp/linkpearl.err 2>/dev/null | tail -20