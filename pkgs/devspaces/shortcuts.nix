{ lib, writeScriptBin, bash, symlinkJoin }:

let
  theme = import ./theme.nix;
  
  # Create a setup shortcut script for each devspace
  makeShortcut = space: writeScriptBin space.name ''
    #!${bash}/bin/bash
    # ${space.icon} ${space.name} - ${space.description}
    
    # If no arguments and we're in an SSH session (likely from mobile), 
    # connect to the tmux session instead of showing setup
    if [ $# -eq 0 ] && [ -n "$SSH_TTY" ] && [ -z "$TMUX" ]; then
      # Check if the tmux session exists
      if tmux has-session -t devspace-${space.name} 2>/dev/null; then
        exec tmux attach-session -t devspace-${space.name}
      else
        echo "${space.icon} ${space.name} not initialized. Run devspace-init first."
        exit 1
      fi
    else
      # Normal behavior: setup/show devspace configuration
      exec devspace-setup ${space.name} "$@"
    fi
  '';
  
  shortcuts = map makeShortcut theme.spaces;
in
symlinkJoin {
  name = "devspace-shortcuts";
  paths = shortcuts;
}