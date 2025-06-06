{ inputs, lib, config, pkgs, ... }: 
let
  # Get claude-code-ntfy package from flake input
  claude-code-ntfy = inputs.claude-code-ntfy.packages.${pkgs.system}.default;
in
{
  # Install Node.js to enable npm
  home.packages = with pkgs; [
    nodejs_20
    # Add claude-code-ntfy wrapper
    claude-code-ntfy
  ];

  # Add npm global bin to PATH for user-installed packages
  # Put claude-code-ntfy first so it takes precedence
  home.sessionPath = [ 
    "${claude-code-ntfy}/bin"
    "$HOME/.npm-global/bin" 
  ];
  
  # Set npm prefix to user directory
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    # Ensure claude-code-ntfy wrapper is found first
    PATH = "${claude-code-ntfy}/bin:$PATH";
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
