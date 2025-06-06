#!/bin/bash
# Diagnose linkpearl service issues

echo "=== Current service status ==="
launchctl list | grep linkpearl

echo -e "\n=== Unloading old service ==="
launchctl bootout gui/$(id -u)/org.nix-community.home.linkpearl 2>/dev/null

echo -e "\n=== Clearing old logs ==="
rm -f /tmp/linkpearl.out /tmp/linkpearl.err

echo -e "\n=== Loading service fresh ==="
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.linkpearl.plist

echo -e "\n=== Waiting for service to start ==="
sleep 3

echo -e "\n=== Service status after reload ==="
launchctl list | grep linkpearl

echo -e "\n=== Checking logs ==="
echo "STDOUT (/tmp/linkpearl.out):"
cat /tmp/linkpearl.out 2>/dev/null || echo "(no output)"

echo -e "\nSTDERR (/tmp/linkpearl.err):"
cat /tmp/linkpearl.err 2>/dev/null || echo "(no errors)"

echo -e "\n=== Testing binary directly with same args ==="
echo "Running: /nix/store/26b5yzzqpixi3cpcg6b364n0gl769shx-linkpearl-0.1.0/bin/linkpearl run --poll-interval 500ms"
echo "With env vars from plist:"
export LINKPEARL_JOIN="ultraviolet:9437"
export LINKPEARL_NODE_ID="cloudbank"
export LINKPEARL_SECRET_FILE="/Users/joshsymonds/.config/linkpearl/secret"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

env | grep LINKPEARL

echo -e "\n(Press Ctrl+C to stop the test)"
/nix/store/26b5yzzqpixi3cpcg6b364n0gl769shx-linkpearl-0.1.0/bin/linkpearl run --poll-interval 500ms