{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication rec {
  pname = "checkov";
  version = "3.2.334";

  src = fetchFromGitHub {
    owner = "bridgecrewio";
    repo = pname;
    rev = version;
    hash = "sha256-UY3EXGOo9xXU/Iqzwk2+pcbtMYQwuEU9G3uETWL3o2o=";
  };

  pythonRelaxDeps = true;

  nativeBuildInputs = with python3Packages; [
    pythonRelaxDepsHook
    setuptools-scm
  ];

  propagatedBuildInputs = with python3Packages; [
    aiodns
    aiohttp
    aiomultiprocess
    argcomplete
    boto3
    cachetools
    charset-normalizer
    cloudsplaining
    colorama
    configargparse
    cyclonedx-python-lib
    docker
    dockerfile-parse
    dpath
    gitpython
    igraph
    jmespath
    jsonpath-ng
    jsonschema
    junit-xml
    license-expression
    networkx
    openai
    packaging
    policyuniverse
    prettytable
    pycep-parser
    pydantic
    python-hcl2
    pyyaml
    regex
    requests
    rich
    rustworkx
    schema
    semver
    spdx-tools
    tabulate
    termcolor
    tqdm
    typing-extensions
    update-checker
    yarl
  ];

  # Tests require network access and additional dependencies
  doCheck = false;

  pythonImportsCheck = [
    "checkov"
  ];

  meta = with lib; {
    description = "Static code analysis tool for infrastructure-as-code";
    homepage = "https://github.com/bridgecrewio/checkov";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "checkov";
  };
}