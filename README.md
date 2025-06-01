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

