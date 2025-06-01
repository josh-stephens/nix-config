{ lib, stdenv, pkgs, symlinkJoin }:

let
  devspaceInit = pkgs.callPackage ./devspace-init.nix { };
  devspaceSetup = pkgs.callPackage ./devspace-setup.nix { };
  devspaceStatus = pkgs.callPackage ./devspace-status.nix { };
  devspaceWorktree = pkgs.callPackage ./devspace-worktree.nix { };
  shortcuts = pkgs.callPackage ./shortcuts.nix { };
in
symlinkJoin {
  name = "devspaces";
  paths = [ devspaceInit devspaceSetup devspaceStatus devspaceWorktree shortcuts ];
}