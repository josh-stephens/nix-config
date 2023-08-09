{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs.unstable; [
      csharp-ls
      file
      unzip
      nvtop
      psensor
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  programs.nixneovim.plugins.lsp.servers.csharp_ls.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
