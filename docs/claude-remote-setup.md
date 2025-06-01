# Claude Code Remote Development Setup with tmux

## Project Goal

Create a persistent remote development environment where multiple Claude Code instances can run continuously on NixOS servers, accessible from various clients (Mac, mobile, etc.) via Tailscale, without requiring constant connection or monitoring.

## Core Requirements

### 1. Persistent Development Sessions
- **5 named sessions** using planetary theme (mercury, venus, earth, mars, jupiter)
- Sessions must survive client disconnection and server reboots
- Each session should maintain its working directory and state
- Claude Code processes should continue running when no client is attached
- Push notifications from terminal bells via nfty.sh

### 2. Naming Convention & Mental Model
- **mercury** - Quick experiments, ephemeral work
- **venus** - Personal creative/web projects  
- **earth** - Primary work project (home base)
- **mars** - Secondary work project (frontier exploration)
- **jupiter** - Large personal project (the giant)

This provides natural ordering and memorable associations without requiring per-project naming.

### 3. Client Access Requirements

#### Mac (Primary Development)
- Quick keyboard shortcuts to connect to any devspace (ideally Cmd+1 through Cmd+5)
- Visual indicators showing which environment is active
- Seamless connection via Tailscale SSH
- Proper terminal emulation (works well with Kitty)
- Copy/paste functionality between local and remote

#### Mobile (iOS via Blink Shell or similar)
- Simple commands to attach to sessions (e.g., type "earth" to connect)
- Readable fonts and proper touch scrolling
- Quick session switching without complex key combinations
- Ability to monitor Claude's progress without active interaction

### 4. Development Environment Structure

Each devspace should support:
- **Multiple windows/panes** within each session:
  - Claude Code instance
  - Neovim for editing
  - General terminal for commands
  - Log viewing/monitoring
- **Isolated workspaces** with dedicated directories
- **Project context** preservation between connections
- **Easy setup** via shell commands (`earth .`, `venus /path/to/workdir`, etc.)
- **Confirmation of teardown** if the above commands are invoked

### 5. Authentication & Credentials

#### Critical: AWS SSO Support
- Must handle AWS SSO credentials that expire
- Need mechanism to sync credentials from Mac to NixOS server
- Should support both work and personal AWS accounts
- Credentials should be available to Claude Code instances

#### Other Credentials
- Git SSH keys (via agent forwarding)
- Kubernetes contexts and configurations
- Any other development tokens/secrets

### 6. Quality of Life Features

#### Status Monitoring
- Quick command to see all devspaces and their current state
- Visual differentiation between environments (colors, emojis) in Starship
- Ability to see what each Claude instance is working on
- No requirement to remember what each session contains

#### Session Management
- Automatic session creation on system boot
- Graceful handling of crashed sessions
- Easy restart/reset of individual devspaces
- Protection against accidental session termination

#### Workflow Integration
- Should feel as natural as opening a new terminal
- Minimal cognitive overhead for switching contexts
- No need to manage session names or remember configurations
- Quick access to the right environment for the current task

## Implementation Details

### Core Architecture

The devspace system is implemented as a Nix package with the following components:

```
pkgs/devspaces/
├── theme.nix                    # Central theme definition
├── devspace-restore.nix         # Main restoration/initialization service
├── devspace-init-single.nix     # Creates individual minimal sessions
├── devspace-setup-enhanced.nix  # Links projects and expands sessions
├── devspace-save-state.nix      # Persists session state
├── devspace-save-hook.nix       # Background state saver
├── devspace-context.nix         # Detects current devspace
├── devspace-worktree.nix        # Git worktree management
├── devspace-status.nix          # Shows all devspace status
└── shortcuts.nix                # Creates earth, mars, etc. commands
```

### 1. Session Lifecycle

#### Boot/Rebuild Process
1. **systemd service** `devspace-restore` runs on boot/rebuild
2. Checks for existing tmux sessions
3. If none exist, reads state from `~/.local/state/tmux-devspaces/sessions.txt`
4. Creates minimal placeholder sessions for each devspace
5. Restores project links if directories still exist

#### Minimal vs Full Sessions
- **Minimal**: Single "setup" window with welcome message and instructions
- **Full**: Four windows (claude, nvim, term, logs) with project directory set
- Transition happens automatically when project is linked

#### State Persistence
State is saved automatically when:
- Project is linked/changed (via save hook)
- Windows are created/destroyed (tmux hooks)
- Client detaches (tmux hook)
- Every 30 minutes (systemd timer)
- System shutdown/rebuild (systemd service)

### 2. Command Structure

All devspace commands follow a consistent pattern:

```bash
<devspace> [command] [args]
```

Examples:
- `earth` - Connect to devspace (creates if needed)
- `earth ~/Work/project` - Link project and connect
- `earth status` - Show configuration
- `earth worktree create feature` - Create git worktree

### 3. Connection Flow

#### From Mac (Client)
1. User runs `earth`
2. ET (Eternal Terminal) connects to server
3. Command checks if tmux session exists
4. If not, runs `devspace-restore` to create it
5. Attaches to tmux session

#### On Server (Direct)
1. Same commands available directly
2. Auto-restore happens if session missing
3. Full environment available immediately

### 4. Git Worktree Management

Automatic isolation when multiple devspaces use same repo:

```bash
# First devspace
earth ~/Work/main-app     # Links directly

# Second devspace  
mars ~/Work/main-app      # Creates worktree at:
                         # ~/devspaces/mars/worktrees/devspace-mars-20241201-143022
```

Worktrees are cleaned up when:
- Branch is merged into main
- Devspace is linked to different project
- User runs `earth worktree clean`

### 5. Theme Integration

Central theme file defines all devspaces:

```nix
# pkgs/devspaces/theme.nix
{
  spaces = [
    {
      name = "mercury";
      icon = "🚀";
      color = "flamingo";  # Catppuccin color
      description = "Quick experiments and prototypes";
      hotkey = "m";        # Meta-M to switch
      connectMessage = "🚀 Launching into Mercury orbit...";
    }
    # ... other spaces
  ];
}
```

### 6. Tmux Configuration

#### Key Bindings (in devspace sessions)
- `Ctrl-b c` - Jump to Claude window
- `Ctrl-b n` - Jump to Neovim window  
- `Ctrl-b t` - Jump to Terminal window
- `Ctrl-b l` - Jump to Logs window
- `Meta-<first-letter>` - Switch between devspace sessions

#### Visual Theming
- Status bar colored by devspace theme color
- Pane borders match devspace color
- Window names clearly labeled

### 7. Notification System

Claude wrapper script monitors for:
- Terminal bells (^G)
- Question patterns (ending with "?")
- Completion patterns ("done", "finished", etc.)
- Error patterns
- Extended idle time

Notifications sent via nfty.sh with devspace context.

### 8. AWS Credential Sync

From Mac:
```bash
devspace-sync-aws              # Syncs to ~/.aws on server
devspace-sync-aws earth        # Also copies to ~/devspaces/earth/.aws
```

Uses rsync over SSH/Tailscale for secure transfer.

### 9. Mobile Access (Blink Shell)

Blink configuration example:
```bash
# Host: ultraviolet
# Command: earth
# Port: 2022 (for ET)
```

Single tap connects directly to devspace.

### 10. Clipboard Integration

- **Copy**: OSC52 sequences work in SSH/ET sessions
- **Paste**: Use Cmd-V in terminal (native terminal paste)
- Internal vim operations use registers normally

## File Structure

### Server Side
```
~/devspaces/
├── mercury/
│   ├── project -> /home/user/Work/some-project (symlink)
│   └── worktrees/
│       └── devspace-mercury-20241201-143022/
├── venus/
├── earth/
├── mars/
└── jupiter/

~/.local/state/tmux-devspaces/
└── sessions.txt  # Saved session state
```

### Configuration Files
```
hosts/ultraviolet/tmux.nix      # Server tmux/devspace configuration
home-manager/devspaces-client/  # Mac client commands
home-manager/tmux/              # Tmux configuration with hooks
pkgs/devspaces/                 # Core implementation
```

## Troubleshooting

### Common Issues

1. **Session not found after rebuild**
   - Check: `systemctl status devspace-restore`
   - Fix: `devspace-restore` manually

2. **Can't connect to devspace**
   - Check: `tmux ls` on server
   - Fix: Kill stuck session and reconnect

3. **State not saving**
   - Check: `~/.local/state/tmux-devspaces/sessions.txt`
   - Fix: `save_session_state` manually

4. **Project link broken**
   - Check: `earth status`
   - Fix: `earth /path/to/project` to relink

### Debug Commands
```bash
# View systemd logs
journalctl -u devspace-restore -f
journalctl -u devspace-save-state -f

# Check tmux environment
tmux show-environment -t devspace-earth

# Force state save
save_session_state

# Manual restore
devspace-restore
```

## Future Enhancements

1. **Enhanced Mobile UI**: Custom tmux status for small screens
2. **Project Templates**: Auto-setup for common project types
3. **Backup/Sync**: Sync devspace state across servers
4. **Integration**: Direct VSCode/IntelliJ remote development
5. **Metrics**: Track time spent in each devspace

## Success Metrics

The implementation successfully achieves:
- ✅ Zero-friction connection (`earth` from anywhere)
- ✅ Perfect persistence (survives reboots)
- ✅ Clear organization (themed devspaces)
- ✅ Credential simplicity (one sync command)
- ✅ Mobile friendly (Blink integration)
- ✅ Crash resilient (auto-restore)
- ✅ Minimal resource usage (lazy expansion)
- ✅ Git isolation (automatic worktrees)