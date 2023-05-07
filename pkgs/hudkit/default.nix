{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, gcc
, gnumake
, webkitgtk
, gtk3
}:

stdenv.mkDerivation rec {
  pname = "hudkit";
  version = "v4.1.0";

  src = fetchFromGitHub {
    owner = "anko";
    repo = pname;
    rev = version;
    sha256 = "sha256-Itm1CayIkMxwWymirzHOuU/h3+tJ0OFO/jmAH8OIB40=";
  };

  nativeBuildInputs = [ pkg-config gcc gnumake gtk3 webkitgtk ];

  buildPhase = "make";
  installPhase = "cp hudkit $out";

  meta = with lib; {
    homepage = "https://github.com/anko/hudkit";
    description = "HUD for your desktop using WebKit";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
