# From here: https://raw.githubusercontent.com/noib3/dotfiles/master/modules/services/sketchybar.nix

{ config
, lib
, pkgs
, ...
}:

with lib;
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.services.sketchybar;
in
{
  options.services.sketchybar = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the sketchybar hotkey daemon.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.sketchybar;
      description = "Package providing sketchybar.";
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "sketchybar is only supported on darwin";
        }
      ];
    }

    (mkIf cfg.enable {
      # the sketchybar binary should be available to shells for keypress simulation
      # functionality, e.g. exiting out of modes after running a script.
      home.packages = [ cfg.package ];

      launchd.agents.sketchybar = {
        enable = lib.mkDefault true;
        # path = [ config.environment.systemPath ];
        config = {
          ProgramArguments = [
            "${cfg.package}/bin/sketchybar"
          ];
          KeepAlive = true;
          ProcessType = "Interactive";
          EnvironmentVariables = {
            PATH = concatStringsSep ":" [
              "${config.home.homeDirectory}/.nix-profile/bin"
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/"
            ];
          };
          StandardOutPath = "${config.xdg.cacheHome}/sketchybar.out.log";
          StandardErrorPath = "${config.xdg.cacheHome}/sketchybar.err.log";
        };
      };
    })
  ];
}

