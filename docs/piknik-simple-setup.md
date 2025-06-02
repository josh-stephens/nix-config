# Simple Piknik Setup

## One-Time Setup

### 1. Generate Config (on Mac)
```bash
# Generate a complete config with keys
piknik -genkeys > ~/.piknik.toml.generated

# For Mac (server), create ~/.piknik.toml with:
# - Copy everything from "# Configuration for a server" section
# - Include all the key lines (Psk, SignPk, etc.)
# - Set Listen = "0.0.0.0:8075"

# For Linux (clients), create ~/.piknik.toml with:
# - Copy everything from "# Configuration for a client" section  
# - Use THE SAME key values as the server
# - Set Connect = "cloudbank:8075" (or your Mac's hostname)
```

### 2. Test Connection
```bash
# On Mac
echo "test from mac" | piknik -copy

# On Linux  
piknik -paste
# Should show: "test from mac"
```

### 3. Enable Auto-Sync (Optional)
```bash
# On Mac - rebuild to start clipboard monitor
update

# This watches Mac clipboard and auto-syncs to piknik
# Your Mac clipboard still works normally if this stops
```

## That's It!

- Mac clipboard always works normally
- Clipboard monitor just adds remote sync capability
- If anything breaks, Mac clipboard is unaffected
- Manual sync always available: `mac-to-piknik`