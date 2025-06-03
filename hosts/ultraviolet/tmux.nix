{ config, lib, pkgs, ... }:

{
  # System-wide tmux installation
  environment.systemPackages = with pkgs; [ 
    tmux
  ];
}
