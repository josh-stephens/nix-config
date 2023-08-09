{ inputs
, self
, pins
, lib
, build
, pkgs
, pkgsCross
, pkgsi686Linux
, callPackage
, fetchFromGitHub
, fetchurl
, moltenvk
, supportFlags
, stdenv_32bit
,
}:
let
  nixpkgs-wine = builtins.path {
    path = inputs.nixpkgs;
    name = "source";
    filter = path: type:
      let
        wineDir = "${inputs.nixpkgs}/pkgs/applications/emulators/wine/";
      in
      (
        (type == "directory" && (lib.hasPrefix path wineDir))
        || (type != "directory" && (lib.hasPrefix wineDir path))
      );
  };

  defaults =
    let
      sources = (import "${inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" { inherit pkgs; }).unstable;
    in
    {
      inherit supportFlags moltenvk;
      patches = [ ];
      buildScript = "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh";
      configureFlags = [ "--disable-tests" ];
      geckos = with sources; [ gecko32 gecko64 ];
      mingwGccs = with pkgsCross; [ mingw32.buildPackages.gcc mingwW64.buildPackages.gcc ];
      monos = with sources; [ mono ];
      pkgArches = [ pkgs pkgsi686Linux ];
      platforms = [ "x86_64-linux" ];
      stdenv = stdenv_32bit;
    };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in
{
  wine-xiv = callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix"
    (lib.recursiveUpdate defaults
      rec {
        pname = pnameGen "wine-xiv";
        version = "v8.12";
        src = fetchFromGitHub {
          owner = "rankynbass";
          repo = "unofficial-wine-xiv-git";
          rev = "v8.12";
          sha256 = "";
        };
        supportFlags.waylandSupport = true;
      });
}
