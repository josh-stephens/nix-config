{ lib, writeScriptBin, bash, symlinkJoin, devspace-context, devspace-setup, devspace-worktree, devspace-restore, devspace-welcome }:

let
  theme = import ./theme.nix;
  
  # Create a versatile shortcut script for each devspace
  makeShortcut = space: writeScriptBin space.name ''
    #!${bash}/bin/bash
    # ${space.icon} ${space.name} - ${space.description}
    
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
        tmux start-server 2>/dev/null || true
        
        # Try to attach to existing session first
        if tmux has-session -t devspace-${toString space.id} 2>/dev/null; then
          # Just attach - session already exists
          exec tmux attach-session -t devspace-${toString space.id}
        else
          # Create a new session that will initialize itself
          exec tmux new-session -s devspace-${toString space.id} -n setup \
            -e TMUX_DEVSPACE="${space.name}" \
            -e TMUX_DEVSPACE_COLOR="${space.color}" \
            -e TMUX_DEVSPACE_ICON="${space.icon}" \
            -e TMUX_DEVSPACE_ID="${toString space.id}" \
            "${devspace-welcome}/bin/devspace-welcome ${space.name}"
        fi
        ;;
      
      # Default behavior
      "")
        # If no arguments and not in tmux, connect to tmux session
        # (Always assume we want to connect when called without args)
        if [ -z "$TMUX" ]; then
          # Ensure tmux server is started
          tmux start-server 2>/dev/null || true
          
          # Try to attach to existing session first
          if tmux has-session -t devspace-${toString space.id} 2>/dev/null; then
            # Just attach - session already exists
            exec tmux attach-session -t devspace-${toString space.id}
          else
            # Create a new session that will initialize itself
            exec tmux new-session -s devspace-${toString space.id} -n setup \
              -e TMUX_DEVSPACE="${space.name}" \
              -e TMUX_DEVSPACE_COLOR="${space.color}" \
              -e TMUX_DEVSPACE_ICON="${space.icon}" \
              -e TMUX_DEVSPACE_ID="${toString space.id}" \
              "${devspace-welcome}/bin/devspace-welcome ${space.name}"
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