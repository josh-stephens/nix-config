{ lib, stdenv, fetchurl, go }:

stdenv.mkDerivation rec {
  pname = "starlark-lsp";
  version = "latest";

  src = ./.;

  nativeBuildInputs = [ go ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    export HOME=$TMPDIR
    export GOPATH=$TMPDIR/go
    export GOCACHE=$TMPDIR/go-cache
    mkdir -p $out/bin
    
    # Install directly from GitHub - the cmd/starlark-lsp path
    ${go}/bin/go install github.com/tilt-dev/starlark-lsp/cmd/starlark-lsp@latest
    
    # Copy the binary to our output (it's already named starlark-lsp)
    cp $GOPATH/bin/starlark-lsp $out/bin/
  '';

  meta = with lib; {
    description = "Starlark Language Server Protocol implementation";
    homepage = "https://github.com/tilt-dev/starlark-lsp";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
