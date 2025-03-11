{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.uv ];

  home.file.".aider.model.metadata.json" = {
    source = ./aider/.aider.model.metadata.json;
  };

  home.file.".aider.model.settings.yml" = {
    source = ./aider/.aider.model.settings.yml;
  };

  home.file.".aider.conf.yml" = {
    source = ./aider/.aider.conf.yml;
  };
}
