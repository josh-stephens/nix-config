# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  TotallyNotCef = pkgs.callPackage ./TotallyNotCef { };
  myCaddy = pkgs.callPackage ./caddy { };
  xivlauncherRb = pkgs.callPackage ./xivlauncher { };
  fflogs = pkgs.callPackage ./fflogs { };
}
