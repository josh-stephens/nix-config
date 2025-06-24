# Custom NixOS Modules

This directory contains custom NixOS modules for system-level services and configurations.

## Structure

- `services/` - System service modules
  - `signal-cli-bot.nix` - Signal CLI bot service for automated messaging

## Usage

Import modules in your host configuration:

```nix
imports = [
  ../../modules/services/signal-cli-bot.nix
];
```

Then configure the service:

```nix
services.signal-cli-bot = {
  enable = true;
  phoneNumber = "+1234567890";
};
```

## Adding New Modules

When creating new system-level modules:

1. Place service modules in `services/`
2. Place other system modules directly in `modules/`
3. Include documentation in the same directory
4. Follow NixOS module conventions with options and config sections