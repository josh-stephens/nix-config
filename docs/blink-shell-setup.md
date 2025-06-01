# Blink Shell Setup for Devspaces

## Quick Setup

### Option 1: Blink Hosts (Recommended)

In Blink Shell, go to **Settings → Hosts** and add:

#### Earth (Primary Work)
- **Host**: earth
- **HostName**: ultraviolet
- **User**: joshsymonds
- **Command**: `tmux attach-session -t devspace-earth`

#### Mars (Secondary Work)
- **Host**: mars
- **HostName**: ultraviolet
- **User**: joshsymonds
- **Command**: `tmux attach-session -t devspace-mars`

#### Mercury (Quick Experiments)
- **Host**: mercury
- **HostName**: ultraviolet
- **User**: joshsymonds
- **Command**: `tmux attach-session -t devspace-mercury`

#### Venus (Personal Creative)
- **Host**: venus
- **HostName**: ultraviolet
- **User**: joshsymonds
- **Command**: `tmux attach-session -t devspace-venus`

#### Jupiter (Large Personal Project)
- **Host**: jupiter
- **HostName**: ultraviolet
- **User**: joshsymonds
- **Command**: `tmux attach-session -t devspace-jupiter`

### Option 2: Direct SSH with Aliases

After SSH'ing to ultraviolet, you can now just type:
- `earth` - Connect to primary work
- `mars` - Connect to secondary work
- `mercury` - Connect to experiments
- `venus` - Connect to personal creative
- `jupiter` - Connect to large project

### Tailscale Connection

If on Tailscale network, use the Tailscale hostname or IP instead of local IP.

## Usage

Once configured, just type the devspace name in Blink:
```
earth
```

This will:
1. SSH to ultraviolet
2. Attach to the devspace-earth tmux session
3. Show you exactly where you left off

## Tips

1. **Font Size**: Adjust with pinch gestures
2. **Copy/Paste**: Hold to select, tap to paste
3. **Keyboard**: Cmd+K for keyboard settings
4. **Themes**: Blink supports custom themes - match your Catppuccin setup!

## Notifications

When you get a push notification from nfty.sh showing which devspace needs attention, just:
1. Open Blink
2. Type the devspace name (e.g., `mars`)
3. You're instantly connected