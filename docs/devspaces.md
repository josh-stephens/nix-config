# Devspaces Simplified

This configuration has been dramatically simplified from the previous 12-file implementation to just 3 core files:

## What Changed

### Removed
- All clipboard sync functionality (piknik, monitors, wrappers)
- Complex state management and restoration
- Worktree management
- Project linking system
- 12+ configuration files reduced to 3

### Kept
- Planetary naming (mercury, venus, earth, mars, jupiter)
- Simple tmux session creation on boot
- Easy connection aliases from Mac
- Basic tmux configuration with Catppuccin theme

## New Structure

### Host Configuration (ultraviolet)
- `hosts/ultraviolet/devspaces.nix` - Simple systemd service that creates tmux sessions
- `hosts/ultraviolet/tmux.nix` - Just installs tmux system-wide

### Client Configuration (Mac)
- `home-manager/devspaces-client-simplified/` - Shell aliases for easy connection

### Home Manager
- `home-manager/tmux-simplified/` - Clean tmux configuration without devspace complexity
- Removed all clipboard sync modules

## Usage

From your Mac:
```bash
earth     # Connect to earth devspace
mars      # Connect to mars devspace
venus     # Connect to venus devspace
jupiter   # Connect to jupiter devspace
mercury   # Connect to mercury devspace

ds        # Quick status check
dsl       # Detailed session list
```

The sessions are created automatically on boot as empty tmux sessions. You navigate to whatever directory you want and create windows/panes as needed. No predefined structure or directories.

## Benefits

1. **90% less code** - From ~2000 lines to ~200 lines
2. **No complex state management** - tmux handles persistence natively
3. **No flaky shell expansions** - Direct, simple commands
4. **Native clipboard** - Each platform uses its native clipboard
5. **Reliable** - Simple systemd service, no complex restore logic

## Future

Clipboard sync will be developed as a separate project when needed, focusing on simplicity and reliability.