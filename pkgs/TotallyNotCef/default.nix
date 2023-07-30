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
  rev = "c324f30fb7ccc4fc3d69d3b7a0579933435be884";
in
buildDotnetModule rec {
  pname = "TotallyNotCef";
  version = rev;
  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.runtime_7_0;

  src = fetchFromGitHub {
    owner = "Veraticus";
    repo = "TotallyNotCef";
    rev = rev;
    fetchSubmodules = true;
    hash = "sha256-ap/+4YMJdvXELvmfVJrhCFUpG+d+hSt5g+lKuoJVh7I=";
  };

  nugetDeps = ./deps.nix;

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];

  projectFile = "TotallyNotCef/TotallyNotCef.csproj";

  dotnetFlags = [
  ];

  executables = [ "TotallyNotCef" ];

  runtimeDeps = [ chromium icu openssl ];

  postFixup = ''
    wrapProgram ./TotallyNotCef/bin/Release/linux-x64/publish/TotallyNotCef --set CHROMIUM_PATH ${chromium}/bin/chromium
  '';

  meta = {
    description = "TotallyNotCef";
    homepage = "https://github.com/Veraticus/TotallyNotCef";
    platforms = [ "x86_64-linux" ];
    mainProgram = "TOtallyNotCef";
  };
}
