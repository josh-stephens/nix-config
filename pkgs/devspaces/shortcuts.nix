{ lib, writeScriptBin, bash, symlinkJoin }:

let
  theme = import ./theme.nix;
  
  # Create a setup shortcut script for each devspace
  makeShortcut = space: writeScriptBin space.name ''
    #!${bash}/bin/bash
    # ${space.icon} Setup ${space.name} - ${space.description}
    exec devspace-setup ${space.name} "$@"
  '';
  
  shortcuts = map makeShortcut theme.spaces;
in
symlinkJoin {
  name = "devspace-shortcuts";
  paths = shortcuts;
}