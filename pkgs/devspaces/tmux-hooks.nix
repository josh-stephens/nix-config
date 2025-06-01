{ writeText }:

writeText "devspace-tmux-hooks" ''
  # 🪝 Tmux hooks for automatic state saving
  
  # Save state when windows are created/destroyed in devspace sessions
  set-hook -g window-linked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  set-hook -g window-unlinked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  
  # Save state when panes are created/destroyed (indicates activity)
  set-hook -g after-split-window 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  set-hook -g pane-exited 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  
  # Save state when sessions are renamed or created
  set-hook -g session-created 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  set-hook -g session-renamed 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook\""'
  
  # Save state when client detaches (good time to save)
  set-hook -g client-detached 'run-shell -b "devspace-save-hook"'
''