{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, gnumake
, webkitgtk
, gtk3
, json_c
, keybinder3
, clang
}:

stdenv.mkDerivation rec {
  pname = "hudkit";
  version = "CEF-0.9.3";

  src = fetchFromGitHub {
    owner = "valarnin";
    repo = pname;
    rev = version;
    sha256 = "sha256-rt6nOfHL+iRDM20fFtEHIApd/NQQJDopczwtd2xl948=";
  };

  nativeBuildInputs = [
    pkg-config
    gnumake
    gtk3
    webkitgtk
    json_c
    keybinder3
    clang
  ];

  buildPhase = ''
    cd webkit
    make
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hudkit $out/bin
  '';

  meta = with lib; {
    homepage = "https://github.com/anko/hudkit";
    description = "HUD for your desktop using WebKit";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
