{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
    ../headless-x86_64-linux.nix
  ];

  # Bishop-specific configurations
  # Since this is WSL, you might want some Windows integration
  home.sessionVariables = {
    # Use Windows browser from WSL
    BROWSER = "wslview";
  };

  # WSL-specific aliases
  home.shellAliases = {
    # Open Windows explorer in current directory
    explorer = "explorer.exe .";
    # Access Windows home directory
    winhome = "cd /mnt/c/Users/$USER";
  };
}