{ lib, stdenv, pkgs, symlinkJoin }:

let
  # Core components
  devspaceContext = pkgs.callPackage ./context.nix { };
  devspaceWelcome = pkgs.callPackage ./welcome.nix { };
  devspaceInitSingle = pkgs.callPackage ./init-single.nix { 
    devspace-welcome = devspaceWelcome;
  };
  devspaceStatus = pkgs.callPackage ./status.nix { };
  devspaceWorktree = pkgs.callPackage ./worktree.nix { };
  devspaceSaveState = pkgs.callPackage ./save-state.nix { };
  devspaceSaveHook = pkgs.callPackage ./save-hook.nix { 
    devspace-save-state = devspaceSaveState;
  };
  devspaceSetup = pkgs.callPackage ./setup.nix { 
    devspace-save-hook = devspaceSaveHook;
  };
  devspaceRestore = pkgs.callPackage ./restore.nix { 
    devspace-init-single = devspaceInitSingle;
    devspace-setup = devspaceSetup;
  };
  
  # Shortcuts with dependencies
  shortcuts = pkgs.callPackage ./shortcuts.nix { 
    devspace-context = devspaceContext;
    devspace-setup = devspaceSetup;
    devspace-worktree = devspaceWorktree;
    devspace-restore = devspaceRestore;
    devspace-welcome = devspaceWelcome;
  };
in
symlinkJoin {
  name = "devspaces";
  paths = [ 
    devspaceContext
    devspaceWelcome
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