# Complete Clipboard Sync Setup Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Ultraviolet (Linux)                       │
│                    PIKNIK SERVER (8075)                       │
│                  Always Running, Central Hub                  │
│                                                               │
│  System-wide clipboard wrappers:                              │
│  - pbcopy/pbpaste → piknik → OSC52 fallback                  │
│  - xclip/xsel → piknik → OSC52 fallback                      │
└─────────────────────────────────────────────────────────────┘
                              ↑
                              │ Encrypted
                              │ Network
                              ↓
┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐
│   Mac (Client)   │    │  Blink (Client)  │    │ Other Servers │
│                  │    │                  │    │   (Clients)   │
│ Clipboard Monitor│    │ System wrappers  │    │System wrappers│
│   → piknik       │    │   → piknik       │    │   → piknik    │
└──────────────────┘    └──────────────────┘    └──────────────┘
```

## How It Works

1. **System-Level Wrappers**: We provide system-wide `pbcopy`, `pbpaste`, `xclip`, and `xsel` wrapper scripts
2. **Smart Timeouts**: 200ms timeout ensures no noticeable delay  
3. **Automatic Fallback**: If piknik fails, falls back to OSC52 (terminal clipboard) or native clipboard
4. **Universal**: ALL applications automatically get clipboard sync - no per-app configuration needed
5. **Transparent**: Applications don't know about piknik, they just call standard clipboard commands

## Installation Steps

### Step 1: Generate Encryption Keys (One Time)

On any machine, generate the configuration:

```bash
piknik -genkeys > ~/piknik-config.txt
```

This generates both client and server configurations with matching encryption keys.

### Step 2: Configure Ultraviolet (Piknik Server)

```bash
# Create piknik config with SERVER section only
nano ~/.piknik.toml

# Copy from the generated config:
# - Everything under "# Configuration for a server"
# - Include all the key lines (Psk, SignPk, SignSk, EncryptSk)
# - Make sure Listen = "0.0.0.0:8075"

# Example:
Listen = "0.0.0.0:8075"
Psk    = "a9f5e433e41813bb5de2679d8e9759dc976618074e3c015ea18535f4b533c277"
SignPk = "b8bf5ec7b79b1ce19854e2e2c796c31be47d3141257d335dde6665bbd4170411"
SignSk = "cf1d400a27159dc722b29995fff6e24c9ffc9924557692baaf34c6a3eee9e8fe"
EncryptSk = "a94f4dbc2b38e716c095f5ee1f3201cd78ee48f8592664614d4d5849fe0d1376"
```

Then rebuild to start the server:
```bash
update

# Verify it's running
systemctl --user status piknik-server
# Should show: active (running)

# Test server is listening
ss -tlnp | grep 8075
# Should show: LISTEN on *:8075
```

### Step 3: Configure Your Mac (Piknik Client)

```bash
# Create piknik config with CLIENT section only
nano ~/.piknik.toml

# Copy from the generated config:
# - Everything under "# Configuration for a client"
# - Use THE SAME keys as the server
# - Change Connect to point to your server

# Example:
Connect   = "ultraviolet:8075"  # Or use Tailscale name/IP
Psk       = "a9f5e433e41813bb5de2679d8e9759dc976618074e3c015ea18535f4b533c277"
SignPk    = "b8bf5ec7b79b1ce19854e2e2c796c31be47d3141257d335dde6665bbd4170411"
SignSk    = "cf1d400a27159dc722b29995fff6e24c9ffc9924557692baaf34c6a3eee9e8fe"
EncryptSk = "a94f4dbc2b38e716c095f5ee1f3201cd78ee48f8592664614d4d5849fe0d1376"
```

Then rebuild to activate clipboard monitoring:
```bash
update

# Verify clipboard monitor is running
clipboard-monitor-status
# Should show: com.clipboard.monitor

# Watch the sync happening
clipboard-monitor-logs
# Should show sync messages when you copy
```

### Step 4: Configure Other Linux Clients (Optional)

For any other Linux machines, repeat Step 3 but use their appropriate hostnames.

### Step 5: Test Everything

```bash
# Test 1: Mac → Linux
# On Mac:
echo "Hello from Mac" | pbcopy  # Or Cmd+C anything

# On Linux:
pbpaste  # Should output: Hello from Mac

# Test 2: Linux → Mac
# On Linux:
echo "Hello from Linux" | pbcopy

# On Mac:
piknik-to-mac  # Sync piknik to Mac clipboard
# Then Cmd+V anywhere

# Test 3: Neovim Integration
# On Linux in Neovim:
# Type something, then yy to yank
# Should be available via pbpaste

# Test 4: Offline Fallback
# Disconnect from network
# On Linux:
echo "Offline test" | pbcopy
# Should still work (uses OSC52 fallback)
```

## Troubleshooting

### Piknik Server Not Running
```bash
# On Ultraviolet
systemctl --user status piknik-server
systemctl --user restart piknik-server
journalctl --user -u piknik-server -f
```

### Clipboard Monitor Not Syncing (Mac)
```bash
# Check if monitor is running
clipboard-monitor-status

# Restart it
clipboard-monitor-restart

# Check logs for errors
clipboard-monitor-logs
tail -f ~/Library/Logs/clipboard-monitor.error.log
```

### Test Network Connectivity
```bash
# From client machine
nc -zv ultraviolet 8075
# Should show: Connection succeeded

# Test piknik directly
echo "test" | piknik -copy
piknik -paste
```

### Verify Wrapper Scripts
```bash
# Check which pbcopy is being used
which pbcopy
# Should show: /home/user/.nix-profile/bin/pbcopy

# Test wrapper directly
echo "test" | pbcopy
echo $?  # Should be 0

# Check wrapper with debug
bash -x $(which pbcopy) < /dev/stdin
```

## Key Features

### Automatic Fallback Chain
1. **Piknik** (200ms timeout) - For network clipboard sync
2. **OSC52** - For terminal-local clipboard (SSH sessions)
3. **Native** - Mac's pbcopy/pbpaste if available

### What Works Automatically
- ✅ Neovim yanking and pasting
- ✅ Tmux copy mode
- ✅ Shell pipes (`echo "test" | pbcopy`)
- ✅ Any application using system clipboard
- ✅ Works offline (falls back to local clipboard)

### Security
- All clipboard data is encrypted end-to-end
- Only machines with matching keys can read clipboard
- Server cannot decrypt without keys
- No clipboard data is logged

## Common Commands Reference

### Mac Commands
```bash
clipboard-monitor-status    # Check monitor status
clipboard-monitor-logs      # View sync activity
clipboard-monitor-restart   # Restart monitor
piknik-to-mac              # Pull from piknik to Mac clipboard
mac-to-piknik              # Push Mac clipboard to piknik
```

### Linux Commands
```bash
pbcopy / pbpaste           # Works like Mac, syncs with piknik
clip                       # Alias for piknik -copy
paste                      # Alias for piknik -paste
systemctl --user status piknik-server  # Check server
```

### Testing Commands
```bash
# Test piknik connection
echo "test" | timeout 1 piknik -copy && echo "✓ Connected" || echo "✗ Not connected"

# Test wrapper fallback
echo "test" | pbcopy && echo "✓ Clipboard works"

# Check which clipboard is being used
echo "test" | bash -x $(which pbcopy) 2>&1 | grep -E "piknik|OSC52"
```

## Architecture Benefits

1. **System-Wide**: No per-application configuration needed (no Neovim plugins, no tmux config)
2. **Transparent**: Applications don't know about piknik - they just call `pbcopy`/`pbpaste`
3. **Resilient**: Multiple fallback mechanisms ensure clipboard always works
4. **Fast**: 200ms timeout prevents any noticeable delays
5. **Secure**: End-to-end encryption for network clipboard
6. **Simple**: Just use normal clipboard commands - everything else is automatic

## What Changed from Previous Versions

- **Removed**: Complex Neovim clipboard plugin
- **Removed**: Shell aliases for clipboard commands  
- **Added**: System-level wrapper scripts that handle everything
- **Result**: Much simpler, more maintainable, works everywhere automatically