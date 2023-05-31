{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  src = fetchFromGitHub {
    owner = "Veraticus";
    repo = "media";
    rev = "2a82221d5072272e839d2fe0f636bfe16dea9789";
    sha256 = "sha256-rt6nOfHL+iRDM20fFtEHIApd/NQQJDopczwtd2xl948=";
  };

  buildPhase = "";
  installPhase = ''
    mkdir -p $out/src
    mkdir -p $out/conf
    cp ./docker-compose.yaml $out/conf
    cp ./.env.example $out/conf
  '';
  outputs = [ "src" ];

  meta = with lib;
    {
      homepage = "https://github.com/Veraticus/media";
      description = "Media server setup";
      license = licenses.mit;
      platforms = platforms.linux;
    };
}
