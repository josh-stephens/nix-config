{ lib, stdenv, pkgs, symlinkJoin }:

let
  # Core components
  devspaceContext = pkgs.callPackage ./devspace-context.nix { };
  devspaceInitSingle = pkgs.callPackage ./devspace-init-single.nix { };
  devspaceSetup = pkgs.callPackage ./devspace-setup-enhanced.nix { };
  devspaceStatus = pkgs.callPackage ./devspace-status.nix { };
  devspaceWorktree = pkgs.callPackage ./devspace-worktree.nix { };
  devspaceRestore = pkgs.callPackage ./devspace-restore.nix { };
  devspaceSaveState = pkgs.callPackage ./devspace-save-state.nix { };
  devspaceSaveHook = pkgs.callPackage ./devspace-save-hook.nix { };
  
  # Shortcuts with dependencies
  shortcuts = pkgs.callPackage ./shortcuts.nix { 
    devspace-context = devspaceContext;
    devspace-setup = devspaceSetup;
    devspace-worktree = devspaceWorktree;
  };
in
symlinkJoin {
  name = "devspaces";
  paths = [ 
    devspaceContext 
    devspaceInitSingle
    devspaceSetup 
    devspaceStatus 
    devspaceWorktree 
    devspaceRestore
    devspaceSaveState
    devspaceSaveHook
    shortcuts 
  ];
}