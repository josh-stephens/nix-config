{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, gcc
, gnumake
}:

stdenv.mkDerivation rec {
  pname = "hudkit";
  version = "v4.1.0";

  src = fetchFromGitHub {
    owner = "anko";
    repo = pname;
    rev = version;
    sha256 = "sha256-ORzcd8XGy2BfwuPK5UX+K5Z+FYkb+tdg/gHl3zHjvbk=";
  };

  nativeBuildInputs = [ pkg-config gcc gnumake ];

   meta = with lib; {
    homepage = "https://github.com/anko/hudkit";
    description = "HUD for your desktop using WebKit";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
