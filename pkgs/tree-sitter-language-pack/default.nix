{ lib
, buildPythonPackage
, fetchPypi
, tree-sitter
}:

buildPythonPackage rec {
  pname = "tree-sitter-language-pack";
  version = "0.20.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Yx+Gg/Yt+Ky/Ow0ydRDXZDfLpRkPGVPONu5GGrU+Yk=";
  };

  propagatedBuildInputs = [
    tree-sitter
  ];

  # No tests in the package
  doCheck = false;

  pythonImportsCheck = [ "tree_sitter_language_pack" ];

  meta = with lib; {
    description = "Language pack for tree-sitter";
    homepage = "https://github.com/tree-sitter/tree-sitter-language-pack";
    license = licenses.mit;
  };
}
