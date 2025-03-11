{
  lib,
  stdenv,
  python313,
  fetchFromGitHub,
  gitMinimal,
  portaudio,
  callPackage,
}:

let
  python3 = python313.override {
    self = python3;
    packageOverrides = self: super: { 
      tree-sitter = super.tree-sitter_0_21;
      
      # Custom tree-sitter packages
      tree-sitter-c-sharp = self.buildPythonPackage rec {
        pname = "tree-sitter-c-sharp";
        version = "0.20.0";
        format = "setuptools";
        
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "0000000000000000000000000000000000000000000000000000";
        };
        
        doCheck = false;
        pythonImportsCheck = [ "tree_sitter_c_sharp" ];
        
        propagatedBuildInputs = [ self.tree-sitter ];
      };
      
      tree-sitter-embedded-template = self.buildPythonPackage rec {
        pname = "tree-sitter-embedded-template";
        version = "0.20.0";
        format = "setuptools";
        
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "0000000000000000000000000000000000000000000000000000";
        };
        
        doCheck = false;
        pythonImportsCheck = [ "tree_sitter_embedded_template" ];
        
        propagatedBuildInputs = [ self.tree-sitter ];
      };
      
      tree-sitter-language-pack = self.buildPythonPackage rec {
        pname = "tree-sitter-language-pack";
        version = "0.20.0";
        format = "setuptools";
        
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "0000000000000000000000000000000000000000000000000000";
        };
        
        doCheck = false;
        pythonImportsCheck = [ "tree_sitter_language_pack" ];
        
        propagatedBuildInputs = [ self.tree-sitter ];
      };
      
      tree-sitter-yaml = self.buildPythonPackage rec {
        pname = "tree-sitter-yaml";
        version = "0.20.0";
        format = "setuptools";
        
        src = self.fetchPypi {
          inherit pname version;
          sha256 = "0000000000000000000000000000000000000000000000000000";
        };
        
        doCheck = false;
        pythonImportsCheck = [ "tree_sitter_yaml" ];
        
        propagatedBuildInputs = [ self.tree-sitter ];
      };
    };
  };
  version = "0.76.0";
  aider = python3.pkgs.buildPythonPackage {
    pname = "aider";
    inherit version;
    pyproject = true;

    src = fetchFromGitHub {
      owner = "Aider-AI";
      repo = "aider";
      tag = "v0.76.0";
      hash = "sha256-PbsUNueLXj5WZW8lc+t3cm+ftKWcllYtE2CAsZhuK/s=";
    };

    pythonRelaxDeps = true;

    build-system = with python3.pkgs; [ setuptools-scm ];

    dependencies = with python3.pkgs; [
      aiohappyeyeballs
      aiohttp
      aiosignal
      annotated-types
      anyio
      attrs
      backoff
      beautifulsoup4
      boto3
      certifi
      cffi
      charset-normalizer
      click
      configargparse
      diff-match-patch
      diskcache
      distro
      filelock
      flake8
      frozenlist
      fsspec
      gitdb
      gitpython
      grep-ast
      h11
      httpcore
      httpx
      huggingface-hub
      idna
      importlib-resources
      jinja2
      jiter
      json5
      jsonschema
      jsonschema-specifications
      litellm
      markdown-it-py
      markupsafe
      mccabe
      mdurl
      multidict
      networkx
      numpy
      openai
      packaging
      pathspec
      pexpect
      pillow
      prompt-toolkit
      psutil
      ptyprocess
      pycodestyle
      pycparser
      pydantic
      pydantic-core
      pydub
      pyflakes
      pygments
      pypandoc
      pyperclip
      python-dotenv
      pyyaml
      referencing
      regex
      requests
      rich
      rpds-py
      scipy
      smmap
      sniffio
      socksio
      sounddevice
      soundfile
      soupsieve
      tiktoken
      tokenizers
      tqdm
      tree-sitter
      tree-sitter-languages
      tree-sitter-c-sharp
      tree-sitter-embedded-template
      tree-sitter-language-pack
      tree-sitter-yaml
      typing-extensions
      urllib3
      watchfiles
      wcwidth
      yarl
      zipp
      pip

      # Not listed in requirements
      mixpanel
      monotonic
      posthog
      propcache
      python-dateutil
    ];

    buildInputs = [ portaudio ];

    nativeCheckInputs = (with python3.pkgs; [ pytestCheckHook ]) ++ [ gitMinimal ];

    disabledTestPaths = [
      # Tests require network access
      "tests/scrape/test_scrape.py"
      # Expected 'mock' to have been called once
      "tests/help/test_help.py"
    ];

    disabledTests =
      [
        # Tests require network
        "test_urls"
        "test_get_commit_message_with_custom_prompt"
        # FileNotFoundError
        "test_get_commit_message"
        # Expected 'launch_gui' to have been called once
        "test_browser_flag_imports_streamlit"
        # AttributeError
        "test_simple_send_with_retries"
        # Expected 'check_version' to have been called once
        "test_main_exit_calls_version_check"
        # AssertionError: assert 2 == 1
        "test_simple_send_non_retryable_error"
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # Tests fails on darwin
        "test_dark_mode_sets_code_theme"
        "test_default_env_file_sets_automatic_variable"
        # FileNotFoundError: [Errno 2] No such file or directory: 'vim'
        "test_pipe_editor"
      ];

    makeWrapperArgs = [
      "--set AIDER_CHECK_UPDATE false"
      "--set AIDER_ANALYTICS false"
      # Disable tree-sitter syntax highlighting for problematic languages
      "--set AIDER_DISABLE_SYNTAX_HIGHLIGHT true"
    ];


    preCheck = ''
      export HOME=$(mktemp -d)
      export AIDER_ANALYTICS="false"
    '';

    optional-dependencies = with python3.pkgs; {
      playwright = [
        greenlet
        playwright
        pyee
        typing-extensions
      ];
    };

    passthru = {
      withPlaywright = aider.overridePythonAttrs (
        { dependencies, ... }:
        {
          dependencies = dependencies ++ aider.optional-dependencies.playwright;
        }
      );
    };

    meta = {
      description = "AI pair programming in your terminal";
      homepage = "https://github.com/paul-gauthier/aider";
      changelog = "https://github.com/paul-gauthier/aider/blob/v${version}/HISTORY.md";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ happysalada ];
      mainProgram = "aider";
    };
  };
in
aider
