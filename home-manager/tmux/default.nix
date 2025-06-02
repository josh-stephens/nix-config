{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tmux-devspace;

  # 🪐 Import devspace theme configuration for tmux styling only
  theme = import ../../pkgs/devspaces/theme.nix;
  devspaceConfig = {
    devspaces = map (s: {
      id = s.id;
      name = s.name;
      icon = s.icon;
      color = s.color;
      hotkey = s.hotkey;
    }) theme.spaces;
  };

  # 🔗 Remote link opening script for server side
  remoteLinkOpenScript = pkgs.writeScriptBin "remote-link-open" ''
    #!${pkgs.bash}/bin/bash
    # 🔗 Open links on the client machine when running on a remote server
    
    set -euo pipefail
    
    if [ $# -eq 0 ]; then
      echo "Usage: remote-link-open <url>"
      exit 1
    fi
    
    URL="$1"
    
    # Check if we're in an SSH session
    if [ -z "''${SSH_CLIENT:-}" ]; then
      echo "Not in an SSH session, opening locally..."
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL"
      elif command -v open >/dev/null 2>&1; then
        open "$URL"
      else
        echo "No suitable browser opener found"
        exit 1
      fi
      exit 0
    fi
    
    # Get the client IP
    CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    
    # Use OSC 8 hyperlink sequence that kitty will intercept
    printf '\033]8;;%s\033\\Click to open: %s\033]8;;\033\\\n' "$URL" "$URL"
    
    # Also try to send via kitty remote control if available
    if [ -n "''${KITTY_WINDOW_ID:-}" ]; then
      # Send a notification to kitty that can be intercepted
      printf '\033]99;open-url:%s\033\\' "$URL"
    fi
    
    # Log for debugging
    echo "[$(date)] Remote link open request: $URL from $CLIENT_IP" >> ~/.remote-link-open.log
  '';

in {
  options.programs.tmux-devspace = {
    enable = mkEnableOption "tmux with devspace theming";

    devspaceMode = mkOption {
      type = types.bool;
      default = false;
      description = "Enable devspace-aware tmux theming";
    };

    remoteOpener = mkOption {
      type = types.bool;
      default = false;
      description = "Enable remote link opening (server-side)";
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      terminal = "tmux-256color"; # Required for proper color support
      mouse = true;
      baseIndex = 1; # Windows start at 1
      
      # 🎨 Catppuccin theme plugin and monitoring plugins
      plugins = with pkgs.tmuxPlugins; [
        # System monitoring plugins
        cpu
        net-speed
        
        # Catppuccin theme (must be loaded after dependencies)
        {
          plugin = catppuccin;
          extraConfig = ''
            # Catppuccin settings
            set -g @catppuccin_flavor 'mocha' # latte, frappe, macchiato, mocha
            set -g @catppuccin_window_status_style "rounded" # Enable rounded windows
            
            # Window settings
            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"
            
            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"
            
            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"
            
          '';
        }
      ];

      extraConfig = ''
        # 🔧 General Tmux Settings
        setw -g pane-base-index 1
        set -g renumber-windows on     # Renumber windows when one is closed
        set -g set-titles on           # Set terminal titles
        set -g focus-events on         # For better editor integration (e.g., Neovim)
        set -g status-position bottom  # Display status bar at the bottom
        
        # 📊 Status line configuration (must be after plugins load)
        set -g status-right-length 100
        set -g status-left-length 100
        
        ${optionalString cfg.devspaceMode ''
          # Devspace icon and name on the left - dynamically built from theme
          set -gF status-left "${concatStringsSep "" (map (d: 
            "#{?#{==:#{session_name},devspace-${toString d.id}},${d.icon} ${d.name} ,"
          ) devspaceConfig.devspaces)}"
        ''}
        ${optionalString (!cfg.devspaceMode) ''
          set -g status-left ""
        ''}
        
        # Right side status - Custom modules using Catppuccin's separators and style
        # We can reference the Catppuccin variables directly since the plugin is loaded
        
        # Network module (using teal color from Catppuccin)  
        set -gF @catppuccin_status_network \
          "#[fg=#94e2d5]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#94e2d5]󰈀 #{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.net-speed}/share/tmux-plugins/net-speed/scripts/net_speed.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"
        
        # CPU module (using yellow color from Catppuccin)
        set -gF @catppuccin_status_cpu_custom \
          "#[fg=#f9e2af]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#f9e2af]#{E:@catppuccin_cpu_icon}#{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/cpu_percentage.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"
        
        # RAM module (using mauve color from Catppuccin) - using direct script call
        set -gF @catppuccin_status_ram_custom \
          "#[fg=#cba6f7]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#cba6f7]#(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/ram_icon.sh)#{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/ram_percentage.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"
        
        # Use the modules with expansion
        set -gF status-right "#{E:@catppuccin_status_network}#{E:@catppuccin_status_cpu_custom}#{E:@catppuccin_status_ram_custom}"

        # 🎯 Pane borders - Catppuccin Mocha colors
        set -g pane-border-style "fg=#313244"
        set -g pane-active-border-style "fg=#89b4fa"
        
        ${optionalString cfg.devspaceMode ''
          # Devspace-specific pane colors based on current session
          # These colors are from the Catppuccin Mocha palette
          ${let
            colorMap = {
              flamingo = "#f5c2e7";
              pink = "#f5c2e7";
              red = "#f38ba8";
              green = "#a6e3a1";
              peach = "#fab387";
              mauve = "#cba6f7";
            };
          in concatStringsSep "\n          " (map (d: 
            "if-shell '[ \"#{session_name}\" = \"devspace-${toString d.id}\" ]' \\\n            'set -g pane-active-border-style \"fg=${colorMap.${d.color}}\"'"
          ) devspaceConfig.devspaces)}
        ''}

        # 🌍 Update environment to include devspace variables
        set -ga update-environment " TMUX_DEVSPACE TMUX_DEVSPACE_COLOR TMUX_DEVSPACE_ICON TMUX_DEVSPACE_INITIALIZED"

        # 🔔 Bell settings for notifications
        set -g bell-action any
        set -g visual-bell off
        set -g visual-activity off
        setw -g monitor-activity on

        # 📋 Terminal integration
        set -g allow-passthrough on # Allow OSC52 sequences for clipboard

        ${optionalString cfg.devspaceMode ''
          # 🪝 Devspace state saving hooks (if devspaceMode is enabled)
          set-hook -g window-linked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
          set-hook -g window-unlinked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
          set-hook -g client-detached 'run-shell -b "devspace-save-hook 2>/dev/null || true"'
          set-hook -g session-created 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
        ''}

        # ⌨️ Key bindings
        # 📋 Better copy mode
        bind-key v copy-mode
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # 🔄 Reload config
        bind-key r source-file ~/.tmux.conf \; display-message "⚡ Config reloaded!"

        # 🚪 Better pane management
        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"
        bind-key x kill-pane
        bind-key X kill-window

        # 📍 Navigate panes with vim keys
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        ${optionalString cfg.devspaceMode ''
          # ⌨️ Devspace-specific keybindings
          # Quick window switching with memorable keys
          bind-key c select-window -t :1  # Claude
          bind-key n select-window -t :2  # Neovim
          bind-key t select-window -t :3  # Terminal
          bind-key l select-window -t :4  # Logs

          # 🚀 Quick session switching (theme-based hotkeys)
          ${concatStringsSep "\n          " (map (d:
            "bind-key -n M-${d.hotkey} switch-client -t devspace-${toString d.id}"
          ) devspaceConfig.devspaces)}
        ''}

      ''; # End of extraConfig
    }; # End of programs.tmux

    home.packages = with pkgs; (optionals cfg.remoteOpener [
      remoteLinkOpenScript
    ]);

    # 🌐 Set up environment for remote link opening
    home.sessionVariables = mkIf cfg.remoteOpener {
      BROWSER = "remote-link-open";
      DEFAULT_BROWSER = "remote-link-open";
    };
  }; # End of config
} # End of file