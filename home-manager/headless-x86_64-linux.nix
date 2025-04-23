{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs.unstable; [
      file
      unzip
      dmidecode
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
