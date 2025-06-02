# Clipboard Sync Architecture

## Correct Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Ultraviolet (Linux)                       │
│                    PIKNIK SERVER (8075)                       │
│                  Always Running, Central Hub                  │
└─────────────────────────────────────────────────────────────┘
                              ↑
                              │ Encrypted
                              │ Network
                              ↓
┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐
│   Mac (Client)   │    │  Blink (Client)  │    │ Other Servers │
│                  │    │                  │    │   (Clients)   │
│ Clipboard Monitor│    │  Direct piknik   │    │               │
│   → piknik       │    │     usage        │    │               │
└──────────────────┘    └──────────────────┘    └──────────────┘
```

## Why This Architecture?

1. **Linux Server as Piknik Server**
   - Always online (doesn't sleep like laptops)
   - Accessible from everywhere via Tailscale
   - Central point for all clipboard operations

2. **All Other Devices as Clients**
   - Mac, Blink, other servers connect TO Ultraviolet
   - No port forwarding needed
   - Works through NAT

## Fallback Chain

### On Mac
1. System clipboard (Cmd+C/Cmd+V) - Always works
2. Clipboard monitor → Piknik (if running)
3. Manual sync commands (if monitor stopped)

### On Linux/Neovim
1. Piknik (if server reachable)
2. OSC52 (if piknik down) - Copies to terminal
3. Internal vim registers - Always works

### Key Safety Features
- **Mac clipboard**: Never depends on piknik
- **Neovim yanking**: Falls back to OSC52 if piknik fails
- **Everything degrades gracefully**: No hard dependencies

## Setup Steps

### 1. On Ultraviolet (Server)
```bash
# Generate config
piknik -genkeys > ~/.piknik.toml

# Edit to keep only server section
# Listen = "0.0.0.0:8075"

# Rebuild to start server
update

# Check it's running
systemctl --user status piknik-server
```

### 2. On Mac (Client)
```bash
# Copy the keys from Ultraviolet's ~/.piknik.toml
# Create ~/.piknik.toml with:
# - Client configuration
# - Same keys as server
# - Connect = "ultraviolet:8075"

# Rebuild to start monitor
update
```

### 3. Test
```bash
# From Mac
echo "test" | piknik -copy

# From Ultraviolet
piknik -paste  # Shows "test"
```

## What Happens When Services Are Down?

### Piknik Server Down
- Mac clipboard: ✅ Works normally
- Clipboard monitor: Logs errors but doesn't break anything
- Neovim: ✅ Falls back to OSC52
- Manual sync: ❌ Won't work until server is back

### Clipboard Monitor Down (Mac)
- Mac clipboard: ✅ Works normally
- Auto-sync: ❌ Disabled
- Manual sync: ✅ Still works with `mac-to-piknik`
- Neovim on remote: ✅ Can still paste with piknik

### Everything Down
- Mac clipboard: ✅ Always works
- Neovim: ✅ Uses OSC52 or internal registers
- Copy/paste: Works locally on each machine