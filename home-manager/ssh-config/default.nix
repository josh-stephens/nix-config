{ lib, config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    forwardAgent = true;
    serverAliveInterval = 60;
    
    extraConfig = ''
      # Enable Kitty terminal integration
      SetEnv TERM=xterm-256color
      
      # Forward Kitty's remote control socket
      RemoteForward /tmp/kitty /tmp/kitty
    '';
    
    matchBlocks = {
      "ultraviolet" = {
        hostname = "ultraviolet";
        user = "joshsymonds";
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      
      "bluedesert" = {
        hostname = "bluedesert";
        user = "joshsymonds";
        forwardX11 = true;
        forwardX11Trusted = true;
      };
      
      "echelon" = {
        hostname = "echelon";
        user = "joshsymonds";
        forwardX11 = true;
        forwardX11Trusted = true;
      };
    };
  };
}