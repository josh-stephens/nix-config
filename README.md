# Josh Symonds' Nix Configuration

This repository contains my personal Nix configuration for managing my Mac laptop and Linux home servers using a declarative, reproducible approach with Nix flakes.

## Overview

This configuration manages:
- **macOS laptop** (cloudbank) - M-series Mac with nix-darwin
- **Linux servers** - Multiple headless NixOS home servers:
  - ultraviolet, bluedesert, echelon

## Features

- **Unified Configuration**: Single repository managing both macOS and Linux systems
- **Modular Design**: Separated system-level and user-level configurations
- **Consistent Theming**: Catppuccin Mocha theme across all applications
- **Custom Packages**: Currently includes a customized Caddy web server
- **Development Environment**: Neovim, Git, Starship prompt, and modern CLI tools
- **Simplified Architecture**: Streamlined flake structure with minimal abstraction
- **Devspace Development Environment**: Persistent tmux-based remote development sessions
- **Remote Link Opening**: Seamless browser integration for SSH sessions

## Quick Start

### Rebuild System Configuration

On the target machine, use the `update` alias or run directly:

```bash
# macOS
darwin-rebuild switch --flake ".#$(hostname -s)"

# Linux
sudo nixos-rebuild switch --flake ".#$(hostname)"
```

### Update Flake Inputs

```bash
nix flake update
```

### Build Custom Packages

```bash
nix build .#myCaddy  # Custom Caddy web server
```

## Structure

- `flake.nix` - Main entry point and flake configuration
- `hosts/` - System-level configurations for each machine
  - `common.nix` - Shared configuration for Linux servers (NFS mounts)
- `home-manager/` - User-level dotfiles and application configs
  - `common.nix` - Shared configuration across all systems
  - `aarch64-darwin.nix` - macOS-specific user configuration
  - `headless-x86_64-linux.nix` - Linux server user configuration
  - Individual app modules (neovim, zsh, kitty, etc.)
- `pkgs/` - Custom package definitions
- `overlays/` - Nixpkgs modifications
- `secrets/` - Public keys

## Key Applications

### Development
- **Editor**: Neovim with custom configuration
- **Terminal**: Kitty with Catppuccin theme
- **Shell**: Zsh with syntax highlighting and autosuggestions
- **Version Control**: Git
- **AI Assistance**: Claude Code (automatically installed via npm)

### macOS Desktop
- **Window Manager**: Aerospace
- **Package Management**: Homebrew (declaratively managed)

### Server Applications
- **Kubernetes**: k9s for cluster management
- **File Sharing**: NFS mounts to NAS
- **Web Server**: Custom Caddy build

## Notable Changes from Standard Nix Configs

1. **Simplified Flake Structure**: Removed unnecessary helper functions and abstractions
2. **Unified Nixpkgs**: Using nixpkgs-unstable as primary source
3. **Single Overlay**: Consolidated all overlays into one default overlay
4. **Minimal Special Args**: Only passing essential inputs and outputs
5. **Direct Home Manager Integration**: Home Manager configured directly in flake.nix

## Customization

To add a new system:
1. Create a configuration in `hosts/<hostname>/`
2. Add to `flake.nix` under appropriate section (nixosConfigurations or darwinConfigurations)
3. Add hostname to the appropriate list in homeConfigurations

To add a new package:
1. Create package in `pkgs/<name>/default.nix`
2. Add to `pkgs/default.nix`
3. Add to overlay in `overlays/default.nix` if needed globally

## Devspace Development Environment

The Devspace system provides persistent tmux-based development environments on remote servers, each with its own project context and color theme.

### Available Devspaces
- **Mercury** (flamingo) - Quick experiments
- **Venus** (pink) - Personal creative projects
- **Earth** (green) - Primary work
- **Mars** (red) - Secondary work
- **Jupiter** (peach) - Large personal project

### Usage from macOS

```bash
# Connect to a devspace
earth              # Connect to primary work environment
mars               # Connect to secondary work environment

# Manage devspaces
devspace-status      # Show all devspaces and their linked projects (alias: ds)
devspace-setup earth ~/projects/work/main-app  # Link a devspace to a project
devspace-sync-aws    # Sync AWS credentials from Mac to server (alias: dsa)
```

### Server-side Commands

```bash
# Within tmux sessions
Ctrl-b c          # Switch to Claude window
Ctrl-b n          # Switch to Neovim window
Ctrl-b t          # Switch to Terminal window
Ctrl-b l          # Switch to Logs window

# Quick session switching
Ctrl-b E          # Switch to Earth
Ctrl-b M          # Switch to Mars
# ... etc
```

## Remote Link Opening

When SSH'd into a server, links can be opened on your local Mac browser automatically. This is especially useful for AWS SSO authentication.

### How it Works
1. The server sets `BROWSER=remote-link-open`
2. When applications try to open URLs, they display as clickable links in Kitty
3. Click the link in your terminal to open it in your Mac browser

### Example
```bash
# On the server
aws sso login     # Will display a clickable authentication URL
remote-link-open https://example.com  # Manually open a URL
```

## Testing Changes

See [CLAUDE.md](./CLAUDE.md) for detailed testing procedures. Quick summary:

```bash
# Validate configuration
nix flake check

# Preview changes
darwin-rebuild switch --flake ".#$(hostname -s)" --dry-run

# Build specific components
nix build .#homeConfigurations."joshsymonds@$(hostname -s)".activationPackage
```

