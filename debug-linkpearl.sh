#!/bin/bash
# Debug script for linkpearl on macOS

echo "=== Checking launchd plist ==="
if [ -f ~/Library/LaunchAgents/org.nixos.linkpearl.plist ]; then
    echo "Found plist file. Contents:"
    cat ~/Library/LaunchAgents/org.nixos.linkpearl.plist
else
    echo "ERROR: Plist file not found at ~/Library/LaunchAgents/org.nixos.linkpearl.plist"
    echo "Checking other locations..."
    find ~/Library/LaunchAgents -name "*linkpearl*" 2>/dev/null
fi

echo -e "\n=== Checking environment variables ==="
echo "Running: launchctl print gui/$(id -u)/org.nixos.linkpearl"
launchctl print gui/$(id -u)/org.nixos.linkpearl 2>&1 | grep -A20 "environment variables" || echo "Service not found or no env vars"

echo -e "\n=== Manual test ==="
echo "Testing linkpearl with expected config..."
export LINKPEARL_SECRET_FILE="$HOME/.config/linkpearl/secret"
export LINKPEARL_JOIN="ultraviolet:9437"
export LINKPEARL_NODE_ID="cloudbank"
export LINKPEARL_VERBOSE="true"

echo "Environment variables set:"
env | grep LINKPEARL

echo -e "\n=== Checking if linkpearl binary exists ==="
which linkpearl || echo "linkpearl not found in PATH"

echo -e "\n=== Testing linkpearl manually ==="
echo "Running: linkpearl run --poll-interval 500ms"
echo "(Press Ctrl+C to stop)"