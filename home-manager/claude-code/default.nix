{ inputs, lib, config, pkgs, ... }: {
  # Install Node.js to enable npm
  home.packages = with pkgs; [
    nodejs_20
  ];

  # Add npm global bin to PATH for user-installed packages
  home.sessionPath = [ "$HOME/.npm-global/bin" ];
  
  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  # Install Claude Code on activation
  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PATH="${pkgs.nodejs_20}/bin:$PATH"
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    
    if ! command -v claude >/dev/null 2>&1; then
      echo "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
    else
      echo "Claude Code is already installed at $(which claude)"
    fi
  '';
}