{ writeScriptBin, bash, devspace-save-state }:

writeScriptBin "devspace-save-hook" ''
  #!${bash}/bin/bash
  # 🪝 Hook to save state after meaningful devspace events
  
  # This is called by other devspace commands after significant changes
  # Run in background to not block the main command
  (
    # Small delay to ensure tmux state is settled
    sleep 0.5
    
    # Save the state
    ${devspace-save-state}/bin/save_session_state >/dev/null 2>&1
  ) &
  
  # Return immediately
  exit 0
''