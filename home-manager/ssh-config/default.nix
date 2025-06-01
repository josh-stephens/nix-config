{ lib, config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    forwardAgent = true;
    serverAliveInterval = 60;
    
    extraConfig = ''
      # Enable Kitty terminal integration
      SetEnv TERM=xterm-256color
      
      # Performance optimizations
      Compression yes
      TCPKeepAlive yes
      
      # Use faster ciphers for better responsiveness
      Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
      
      # Reuse connections for faster subsequent connections
      ControlMaster auto
      ControlPath ~/.ssh/control-%h-%p-%r
      ControlPersist 10m
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