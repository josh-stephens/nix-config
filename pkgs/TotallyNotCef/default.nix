{ lib
, buildDotnetModule
, fetchFromGitHub
, dotnetCorePackages
, makeWrapper
, copyDesktopItems
, chromium
, icu
, openssl
, speechd
}:

let
  rev = "2c013457531439e1907299b34e5d5cac5c79302a";
in
buildDotnetModule rec {
  pname = "TotallyNotCef";
  version = "1.0.0";
  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.runtime_7_0;
  runtimeId = "linux-x64";

  src = fetchFromGitHub {
    owner = "Veraticus";
    repo = "TotallyNotCef";
    rev = rev;
    fetchSubmodules = true;
    hash = "sha256-1K2EMJ1/wOHQWPnoks7Vk7uQms0Ypdm2aoGaR/Sr2nQ=";
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

  runtimeDeps = [ speechd chromium icu openssl ];

  postFixup = ''
    wrapProgram $out/bin/TotallyNotCef \
      --set CHROME_PATH ${chromium}/bin/chromium \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        speechd
      ]}"
  '';

  meta = {
    description = "TotallyNotCef";
    homepage = "https://github.com/Veraticus/TotallyNotCef";
    platforms = [ "x86_64-linux" ];
    mainProgram = "TotallyNotCef";
  };
}
