# Clipboard Sync Setup Guide

## Initial Setup on Mac

### 1. Generate Encryption Key (One Time Only)
```bash
# Generate secure keys
piknik -genkeys

# Save ONLY the key lines to a file (4 lines)
piknik -genkeys | grep -E '^(Psk|SignPk|SignSk|EncryptSk)' | head -4 > ~/.piknik.toml.key

# This extracts lines like:
# Psk       = "a9f5e433e41813bb5de2679d8e9759dc976618074e3c015ea18535f4b533c277"
# SignPk    = "b8bf5ec7b79b1ce19854e2e2c796c31be47d3141257d335dde6665bbd4170411"
# SignSk    = "cf1d400a27159dc722b29995fff6e24c9ffc9924557692baaf34c6a3eee9e8fe"
# EncryptSk = "a94f4dbc2b38e716c095f5ee1f3201cd78ee48f8592664614d4d5849fe0d1376"
```

### 2. Rebuild Your Mac Configuration
```bash
# This will install piknik and start the services
update
```

### 3. Copy Key to All Servers
```bash
# Copy to each server you want to sync with
scp ~/.piknik.toml.key ultraviolet:~/.piknik.toml.key
scp ~/.piknik.toml.key bluedesert:~/.piknik.toml.key
scp ~/.piknik.toml.key echelon:~/.piknik.toml.key
```

### 4. Rebuild on Each Server
```bash
# SSH to each server and run
update
```

## Verify Everything is Working

### Check Services on Mac
```bash
# Check if piknik server is running
piknik-status
# Should show: piknik ... (port 8075)

# Check if clipboard monitor is running
clipboard-monitor-status
# Should show: com.clipboard.monitor

# View clipboard monitor logs
clipboard-monitor-logs
# Should show: "✅ Synced clipboard to piknik" messages
```

### Test the Sync
```bash
# Test 1: Mac to Remote
# 1. Copy something on Mac (Cmd+C from any app)
# 2. Check the monitor log shows it synced
# 3. SSH to a server: earth
# 4. Type: paste
# 5. Your copied text should appear!

# Test 2: Remote to Mac
# 1. On server: echo "Hello from server" | clip
# 2. On Mac: piknik-to-mac
# 3. Cmd+V anywhere - text appears!

# Test 3: Direct piknik test
piknik-test
# Should show: "Testing piknik clipboard sync..."
```

## Managing the Services

### Restart Services (After Key Change)
```bash
# Stop all services
launchctl stop com.piknik.server
launchctl stop com.clipboard.monitor

# Rebuild to regenerate configs with new key
update

# Services will auto-start, or manually start:
launchctl start com.piknik.server
launchctl start com.clipboard.monitor
```

### Quick Restart Commands
```bash
# Restart just clipboard monitor
clipboard-monitor-restart

# Full restart of both services
launchctl stop com.piknik.server && launchctl stop com.clipboard.monitor && sleep 1 && launchctl start com.piknik.server && launchctl start com.clipboard.monitor
```

## Troubleshooting

### If Clipboard Sync Isn't Working

1. **Check piknik server is running**
   ```bash
   lsof -i :8075
   # Should show piknik process
   ```

2. **Check clipboard monitor is running**
   ```bash
   ps aux | grep clipboard-monitor
   # Should show the monitor process
   ```

3. **Verify key is correctly set**
   ```bash
   # Check key file exists
   ls -la ~/.piknik.toml.key
   
   # Check merged config has key
   grep "^key =" ~/.piknik.toml
   ```

4. **Test network connectivity**
   ```bash
   # From server, test connection to Mac
   nc -zv cloudbank 8075
   # Should show: Connection succeeded
   ```

5. **Check logs for errors**
   ```bash
   # Piknik server logs
   tail -f ~/Library/Logs/piknik.error.log
   
   # Clipboard monitor logs
   tail -f ~/Library/Logs/clipboard-monitor.error.log
   ```

### Common Issues

**"No clipboard utilities available" on server**
- This is normal - piknik handles clipboard operations
- Use `clip` or `piknik -copy` instead of `pbcopy`

**Clipboard monitor not syncing**
- Make sure you have a key set up
- Check `~/.piknik.toml` has the key line
- Restart the monitor: `clipboard-monitor-restart`

**Can't connect from server**
- Ensure Mac firewall allows port 8075
- Check Tailscale is connected
- Verify server name in piknik config matches

## Advanced Usage

### Manual Sync Commands
```bash
# When automatic sync isn't enough
mac-to-piknik    # Push Mac clipboard to piknik
piknik-to-mac    # Pull piknik to Mac clipboard
sync-clipboard push  # Same as mac-to-piknik
sync-clipboard pull  # Same as piknik-to-mac
```

### Using with Specific Apps
- **Neovim**: Just use `y` to yank, `p` to paste - it uses piknik automatically
- **Tmux**: Copy mode selections go to piknik automatically
- **Terminal**: Use `clip` command or pipe to `piknik -copy`

### Security Notes
- The key in `~/.piknik.toml.key` is your encryption key
- Never commit this file to git
- All clipboard data is encrypted end-to-end
- Only machines with the same key can read the clipboard

## Quick Reference

**Essential Commands:**
- `piknik-genkeys` - Generate new encryption key
- `piknik-status` - Check if server is running
- `clipboard-monitor-logs` - See what's being synced
- `clipboard-monitor-restart` - Restart the monitor
- `clip` - Copy to piknik (on any machine)
- `paste` - Paste from piknik (on any machine)
- `mac-to-piknik` - Manual push from Mac
- `piknik-to-mac` - Manual pull to Mac