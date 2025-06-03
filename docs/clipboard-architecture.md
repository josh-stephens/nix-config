# Clipboard Sync Architecture

## Correct Architecture

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

## Why This Architecture?

1. **Linux Server as Piknik Server**
   - Always online (doesn't sleep like laptops)
   - Accessible from everywhere via Tailscale
   - Central point for all clipboard operations

2. **All Other Devices as Clients**
   - Mac, Blink, other servers connect TO Ultraviolet
   - No port forwarding needed
   - Works through NAT

## System-Level Integration

### How It Works
1. **Any application** calls standard clipboard commands (`pbcopy`, `xclip`, etc.)
2. **Our wrapper scripts** intercept these calls (installed with high priority in PATH)
3. **Try piknik first** with 200ms timeout
4. **Automatic fallback** to OSC52 or native clipboard if piknik fails
5. **Applications are unaware** - they just use normal clipboard commands

### Fallback Chain

**All Platforms:**
1. Try piknik (200ms timeout) → Network clipboard sync
2. Fall back to OSC52 → Terminal-local clipboard  
3. Fall back to native → System clipboard (if available)

### Key Safety Features
- **Zero configuration per app**: Neovim, tmux, shell scripts all "just work"
- **Mac clipboard**: Always works, monitor adds sync capability
- **Fast timeouts**: 200ms prevents any noticeable delay
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
- Mac clipboard: ✅ Works normally (native)
- Linux clipboard: ✅ Falls back to OSC52 automatically
- All applications: ✅ Continue working with local clipboard
- Network sync: ❌ Disabled until server returns

### Clipboard Monitor Down (Mac)
- Mac clipboard: ✅ Works normally
- Mac → Remote sync: ❌ Automatic sync disabled
- Manual sync: ✅ Can still use `mac-to-piknik`
- Remote → Mac: ✅ Still works via `piknik-to-mac`

### Not on Tailnet
- Wrapper timeout: 200ms then fallback (barely noticeable)
- Mac clipboard: ✅ Native clipboard unaffected
- Linux clipboard: ✅ OSC52 fallback works instantly
- All apps: ✅ Continue working with fallback clipboard