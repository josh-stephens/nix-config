{ lib, writeScriptBin, bash, tmux, symlinkJoin, devspace-context, devspace-setup, devspace-worktree, devspace-restore, devspace-welcome }:

let
  theme = import ./theme.nix;
  
  # Create a versatile shortcut script for each devspace
  makeShortcut = space: writeScriptBin space.name ''
    #!${bash}/bin/bash
    # ${space.icon} ${space.name} - ${space.description}
    
    # Function to check if session needs reinitialization
    needs_reinit() {
      local session="devspace-${toString space.id}"
      
      # Check if project is linked
      if [ ! -L "$HOME/devspaces/${space.name}/project" ]; then
        return 1  # No project linked, don't reinit
      fi
      
      local linked_project=$(readlink "$HOME/devspaces/${space.name}/project")
      
      # Check if all required windows exist in correct order
      local windows=$(${tmux}/bin/tmux list-windows -t "$session" -F '#I:#W' 2>/dev/null | sort -n)
      local expected_windows=$'1:claude\n2:nvim\n3:term\n4:logs'
      
      if [ "$windows" != "$expected_windows" ]; then
        return 0  # Windows don't match expected layout
      fi
      
      # Check if the session is already marked as initialized
      local initialized=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
      if [ "$initialized" != "true" ]; then
        return 0  # Not initialized
      fi
      
      # Check the project path stored in the session environment
      local session_project=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_PROJECT 2>/dev/null | cut -d= -f2 || echo "")
      if [ "$session_project" != "$linked_project" ]; then
        return 0  # Project has changed
      fi
      
      return 1  # Everything looks good
    }
    
    # Handle different operations based on arguments
    case "''${1:-}" in
      # Setup/link operations
      setup|link)
        shift
        exec ${devspace-setup}/bin/devspace-setup ${space.name} "$@"
        ;;
      
      # Status operation
      status|info)
        echo "${space.icon} ${space.name} status:"
        ${devspace-setup}/bin/devspace-setup ${space.name}
        ;;
      
      # Worktree operations
      worktree|wt)
        shift
        exec ${devspace-worktree}/bin/devspace-worktree "$@" ${space.name}
        ;;
      
      # Connect operation (explicit)
      connect|attach|tmux)
        # Ensure tmux server is started
        ${tmux}/bin/tmux start-server 2>/dev/null || true
        
        # Try to attach to existing session first
        if ${tmux}/bin/tmux has-session -t devspace-${toString space.id} 2>/dev/null; then
          # Check if we need to reinitialize the session
          if needs_reinit; then
            # Reinitialize the session
            ${devspace-setup}/bin/devspace-setup ${space.name} >/dev/null 2>&1
          fi
          # Attach to the session
          exec ${tmux}/bin/tmux attach-session -t devspace-${toString space.id}
        else
          # Create a new session that will initialize itself
          exec ${tmux}/bin/tmux new-session -s devspace-${toString space.id} -n setup \
            -e TMUX_DEVSPACE="${space.name}" \
            -e TMUX_DEVSPACE_COLOR="${space.color}" \
            -e TMUX_DEVSPACE_ICON="${space.icon}" \
            -e TMUX_DEVSPACE_ID="${toString space.id}" \
            "${bash}/bin/bash -c '${devspace-welcome}/bin/devspace-welcome ${space.name}; exec \$SHELL'"
        fi
        ;;
      
      # Default behavior
      "")
        # If no arguments and not in tmux, connect to tmux session
        # (Always assume we want to connect when called without args)
        if [ -z "$TMUX" ]; then
          # Ensure tmux server is started
          ${tmux}/bin/tmux start-server 2>/dev/null || true
          
          # Try to attach to existing session first
          if ${tmux}/bin/tmux has-session -t devspace-${toString space.id} 2>/dev/null; then
            # Check if we need to reinitialize the session
            if needs_reinit; then
              # Reinitialize the session
              ${devspace-setup}/bin/devspace-setup ${space.name} >/dev/null 2>&1
            fi
            # Attach to the session
            exec ${tmux}/bin/tmux attach-session -t devspace-${toString space.id}
          else
            # Create a new session that will initialize itself
            exec ${tmux}/bin/tmux new-session -s devspace-${toString space.id} -n setup \
              -e TMUX_DEVSPACE="${space.name}" \
              -e TMUX_DEVSPACE_COLOR="${space.color}" \
              -e TMUX_DEVSPACE_ICON="${space.icon}" \
              -e TMUX_DEVSPACE_ID="${toString space.id}" \
              "${bash}/bin/bash -c '${devspace-welcome}/bin/devspace-welcome ${space.name}; exec \$SHELL'"
          fi
        else
          # Otherwise show status
          exec $0 status
        fi
        ;;
      
      # Path argument - treat as setup
      *)
        # If first arg looks like a path, treat as setup
        if [ -d "$1" ] || [ "$1" = "." ] || [[ "$1" == /* ]] || [[ "$1" == ~/* ]]; then
          exec ${devspace-setup}/bin/devspace-setup ${space.name} "$@"
        else
          # Show help
          echo "Usage: ${space.name} [command] [options]"
          echo ""
          echo "Commands:"
          echo "  <path>           Link ${space.name} to a project directory"
          echo "  status           Show ${space.name} status and configuration"
          echo "  connect          Connect to ${space.name} tmux session"
          echo "  worktree <cmd>   Manage git worktrees for ${space.name}"
          echo ""
          echo "Examples:"
          echo "  ${space.name} ~/projects/myapp     # Link to project"
          echo "  ${space.name} .                    # Link to current directory"
          echo "  ${space.name} status               # Show current setup"
          echo "  ${space.name} worktree create feature-branch"
          echo ""
          echo "When connected via SSH/ET, running '${space.name}' attaches to the tmux session."
          exit 1
        fi
        ;;
    esac
  '';
  
  shortcuts = map makeShortcut theme.spaces;
in
symlinkJoin {
  name = "devspace-shortcuts";
  paths = shortcuts;
}