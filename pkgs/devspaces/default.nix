{ lib, stdenv, pkgs, symlinkJoin }:

let
  # Core components
  devspaceContext = pkgs.callPackage ./devspace-context.nix { };
  devspaceInitSingle = pkgs.callPackage ./devspace-init-single.nix { };
  devspaceStatus = pkgs.callPackage ./devspace-status.nix { };
  devspaceWorktree = pkgs.callPackage ./devspace-worktree.nix { };
  devspaceSaveState = pkgs.callPackage ./devspace-save-state.nix { };
  devspaceSaveHook = pkgs.callPackage ./devspace-save-hook.nix { 
    devspace-save-state = devspaceSaveState;
  };
  devspaceSetup = pkgs.callPackage ./devspace-setup-enhanced.nix { 
    devspace-save-hook = devspaceSaveHook;
  };
  devspaceRestore = pkgs.callPackage ./devspace-restore.nix { 
    devspace-init-single = devspaceInitSingle;
    devspace-setup = devspaceSetup;
  };
  
  # Shortcuts with dependencies
  shortcuts = pkgs.callPackage ./shortcuts.nix { 
    devspace-context = devspaceContext;
    devspace-setup = devspaceSetup;
    devspace-worktree = devspaceWorktree;
    devspace-restore = devspaceRestore;
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