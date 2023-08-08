{ lib
, buildDotnetModule
, fetchFromGitHub
, dotnetCorePackages
, makeWrapper
, copyDesktopItems
, chromium
, icu
, openssl
}:

let
  rev = "36b6828d5c01383e29242f0767a058be9185f755";
in
buildDotnetModule rec {
  pname = "TotallyNotCef";
  version = "1.0.0";
  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.runtime_7_0;
  runtimeId = "linux-x64";

  src = fetchFromGitHub {
    owner = "joshua-software-dev";
    repo = "TotallyNotCef";
    rev = rev;
    fetchSubmodules = true;
    hash = "sha256-SNwYRfapM0/vInOXBdRT4TbFAkjQBWaAOVTDXtBwLB0=";
  };

  nugetDeps = ./deps.nix;

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];

  projectFile = "TotallyNotCef/TotallyNotCef.csproj";

  dotnetFlags = [
    "-p:ImportByWildcardBeforeSolution=false"
  ];

  dotnetBuildFlags = [
    "-r linux-x64"
  ];

  dotnetInstallFlags = [
    "-r linux-x64"
  ];

  executables = [ "TotallyNotCef" ];

  runtimeDeps = [ chromium icu openssl ];

  postFixup = ''
    wrapProgram $out/bin/TotallyNotCef --set CHROME_PATH ${chromium}/bin/chromium
  '';

  meta = {
    description = "TotallyNotCef";
    homepage = "https://github.com/Veraticus/TotallyNotCef";
    platforms = [ "x86_64-linux" ];
    mainProgram = "TOtallyNotCef";
  };
}
