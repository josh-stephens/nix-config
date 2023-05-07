{ pkgs ? (import ../nixpkgs.nix) { } }: {
  hudkit = pkgs.callPackage ./hudkit { };
}
