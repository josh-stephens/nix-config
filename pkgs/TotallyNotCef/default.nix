{ lib
, buildDotnetModule
, fetchFromGitLab
, dotnetCorePackages
, makeWrapper
, copyDesktopItems
, chromium
, icu
, openssl
, speechd
}:

let
  rev = "6d9d6a3834d90300418ba0de5ab0ce8586548672";
in
buildDotnetModule rec {
  pname = "TotallyNotCef";
  version = "1.0.0.10";
  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.runtime_7_0;
  runtimeId = "linux-x64";

  src = fetchFromGitLab {
    owner = "joshua.software.dev";
    repo = "TotallyNotCef";
    rev = rev;
    fetchSubmodules = true;
    hash = "sha256-tICIZ9OL9jEzg+mOKbCcaZ4YpMdnhlTUdDi34axgxYY=";
  };

  nugetDeps = ./deps.nix;

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];

  projectFile = "TotallyNotCef/TotallyNotCef.csproj";

  dotnetFlags = [
    "-p:ImportByWildcardBeforeSolution=false"
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
    homepage = "https://gitlab.com/joshua.software.dev/TotallyNotCef/-/releases";
    platforms = [ "x86_64-linux" ];
    mainProgram = "TotallyNotCef";
  };
}
