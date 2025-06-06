#!/bin/bash
# Fix linkpearl on Mac by creating a wrapper script

echo "=== Creating linkpearl wrapper script ==="
cat > ~/.config/linkpearl/start.sh << 'EOF'
#!/bin/bash
export LINKPEARL_SECRET_FILE="$HOME/.config/linkpearl/secret"
export LINKPEARL_JOIN="ultraviolet:9437"
export LINKPEARL_NODE_ID="cloudbank"
export LINKPEARL_POLL_INTERVAL="500ms"

exec /etc/profiles/per-user/joshsymonds/bin/linkpearl run
EOF

chmod +x ~/.config/linkpearl/start.sh

echo "=== Creating custom launchd plist ==="
cat > ~/Library/LaunchAgents/com.linkpearl.custom.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.linkpearl.custom</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.config/linkpearl/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/linkpearl-custom.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/linkpearl-custom.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/etc/profiles/per-user/joshsymonds/bin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
</dict>
</plist>
EOF

echo "=== Unloading any existing linkpearl services ==="
launchctl bootout gui/$(id -u)/org.nix-community.home.linkpearl 2>/dev/null
launchctl bootout gui/$(id -u)/com.linkpearl.custom 2>/dev/null

echo "=== Loading custom linkpearl service ==="
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.linkpearl.custom.plist

echo "=== Checking status ==="
sleep 2
launchctl list | grep linkpearl

echo -e "\n=== Checking logs ==="
tail -10 /tmp/linkpearl-custom.out 2>/dev/null
tail -10 /tmp/linkpearl-custom.err 2>/dev/null