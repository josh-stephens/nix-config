{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.aider ];

  home.file.".aider.model.metadata.json" = {
    source = ./aider/.aider.model.metadata.json;
    force = true;  # Force update on rebuild
  };

  home.file.".aider.model.settings.yml" = {
    source = ./aider/.aider.model.settings.yml;
    force = true;  # Force update on rebuild
  };

  home.file.".aider.conf.yml" = {
    source = ./aider/.aider.conf.yml;
    force = true;  # Force update on rebuild
  };
}
