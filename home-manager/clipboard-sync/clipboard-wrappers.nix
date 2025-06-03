{ pkgs, ... }:

let
  # Create system-wide clipboard wrapper that handles piknik with fallback
  pbcopyWrapper = pkgs.writeScriptBin "pbcopy" ''
    #!${pkgs.bash}/bin/bash
    # System clipboard wrapper with piknik integration
    
    # Try piknik first with short timeout
    if timeout 0.2 ${pkgs.piknik}/bin/piknik -copy 2>/dev/null; then
      exit 0
    fi
    
    # Fallback to OSC52 if in SSH/terminal
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
      # Use OSC52 escape sequence
      printf "\033]52;c;$(base64)\a"
    elif command -v /usr/bin/pbcopy &>/dev/null; then
      # On Mac, use real pbcopy
      exec /usr/bin/pbcopy "$@"
    fi
  '';
  
  pbpasteWrapper = pkgs.writeScriptBin "pbpaste" ''
    #!${pkgs.bash}/bin/bash
    # System clipboard wrapper with piknik integration
    
    # Try piknik first with short timeout
    result=$(timeout 0.2 ${pkgs.piknik}/bin/piknik -paste 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
      echo -n "$result"
      exit 0
    fi
    
    # Fallback to real pbpaste on Mac
    if command -v /usr/bin/pbpaste &>/dev/null; then
      exec /usr/bin/pbpaste "$@"
    fi
    
    # No fallback available
    exit 1
  '';
  
  # Linux clipboard wrappers
  xclipWrapper = pkgs.writeScriptBin "xclip" ''
    #!${pkgs.bash}/bin/bash
    # xclip wrapper with piknik integration
    
    # Try piknik first
    if timeout 0.2 ${pkgs.piknik}/bin/piknik -copy 2>/dev/null; then
      exit 0
    fi
    
    # Fallback to OSC52
    printf "\033]52;c;$(base64)\a"
  '';
  
  xselWrapper = pkgs.writeScriptBin "xsel" ''
    #!${pkgs.bash}/bin/bash
    # xsel wrapper with piknik integration
    
    # Handle paste operations
    if [[ "$*" == *"-o"* ]] || [[ "$*" == *"--output"* ]]; then
      result=$(timeout 0.2 ${pkgs.piknik}/bin/piknik -paste 2>/dev/null)
      if [ $? -eq 0 ] && [ -n "$result" ]; then
        echo -n "$result"
        exit 0
      fi
      exit 1
    fi
    
    # Handle copy operations
    if timeout 0.2 ${pkgs.piknik}/bin/piknik -copy 2>/dev/null; then
      exit 0
    fi
    
    # Fallback to OSC52
    printf "\033]52;c;$(base64)\a"
  '';

in {
  # Install clipboard wrappers with high priority
  home.packages = with pkgs; [
    (hiPrio pbcopyWrapper)
    (hiPrio pbpasteWrapper)
    (hiPrio xclipWrapper)
    (hiPrio xselWrapper)
  ];
}