# Devspaces Simplification Plan

## Executive Summary

The current devspace implementation has grown too complex with 12+ files, brittle shell expansions, and multiple failure points. This plan outlines how to reduce complexity by 80% while keeping the core value: persistent named development environments with seamless remote access.

## Current State Analysis

### What's Working Well
- **Planetary naming scheme** (mercury, venus, earth, mars, jupiter) - intuitive and memorable
- **Simple connection commands** from Mac (`earth`, `mars`, etc.)
- **Persistent tmux sessions** that survive reboots
- **Eternal Terminal (ET)** for reliable connections

### What's Causing Problems
1. **Over-engineered session management**
   - Complex "minimal vs full" session expansion
   - 12 separate .nix files for ~500 lines of actual logic
   - Brittle shell variable expansion causing tmux naming issues
   
2. **Fragile clipboard sync**
   - Multiple layers: piknik + monitors + wrappers + fallbacks
   - Race conditions between Mac and server monitors
   - Too many failure points

3. **Excessive abstraction**
   - Theme configuration spread across multiple files
   - Scripts calling scripts calling scripts
   - State management more complex than tmux's native persistence

## Simplification Strategy

### Phase 1: Core Devspaces (Week 1)

#### Goal
Reduce devspace implementation from 12 files to 2-3 files max.

#### Implementation
```nix
# hosts/ultraviolet/devspaces.nix
{
  # Single systemd service for session creation
  systemd.services.devspaces = {
    description = "Initialize devspace tmux sessions";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "joshsymonds";
    };
    script = ''
      ${pkgs.tmux}/bin/tmux start-server
      
      # Create sessions with proper working directories
      for space in mercury:~/experiments venus:~/personal earth:~/work/main mars:~/work/secondary jupiter:~/projects/large; do
        name=$(echo $space | cut -d: -f1)
        dir=$(echo $space | cut -d: -f2)
        
        if ! ${pkgs.tmux}/bin/tmux has-session -t $name 2>/dev/null; then
          ${pkgs.tmux}/bin/tmux new-session -d -s $name -c "$dir"
          ${pkgs.tmux}/bin/tmux new-window -t $name:2 -n nvim -c "$dir"
          ${pkgs.tmux}/bin/tmux new-window -t $name:3 -n term -c "$dir"
          ${pkgs.tmux}/bin/tmux new-window -t $name:4 -n logs -c "$dir"
        fi
      done
    '';
  };
}

# home-manager/devspaces-client/default.nix
{
  programs.zsh.shellAliases = {
    # Direct, simple aliases - no complex shell functions
    mercury = "et ultraviolet:2022 -c 'tmux attach-session -t mercury || tmux new-session -s mercury'";
    venus = "et ultraviolet:2022 -c 'tmux attach-session -t venus || tmux new-session -s venus'";
    earth = "et ultraviolet:2022 -c 'tmux attach-session -t earth || tmux new-session -s earth'";
    mars = "et ultraviolet:2022 -c 'tmux attach-session -t mars || tmux new-session -s mars'";
    jupiter = "et ultraviolet:2022 -c 'tmux attach-session -t jupiter || tmux new-session -s jupiter'";
    
    # Status command
    devspace-status = "ssh ultraviolet 'tmux list-sessions 2>/dev/null || echo \"No sessions\"'";
  };
}
```

#### What We Remove
- All the complex restore/save state logic
- Shell expansion complexity
- Worktree management (use git directly)
- Project linking system (just cd to directories)
- Welcome messages and fancy initialization

### Phase 2: Clipboard Sync Separation (Week 2)

#### Goal
Extract clipboard sync into a separate, focused project.

#### New Project: `nix-clipboard-sync`
```nix
# Simple OSC52-based clipboard sync
{
  # Server: No daemon needed, just shell integration
  programs.zsh.initContent = ''
    # Copy command that always uses OSC52
    copy() {
      if [ -t 0 ]; then
        printf "\033]52;c;$(echo -n "$*" | base64)\a"
      else
        printf "\033]52;c;$(base64)\a"
      fi
    }
    
    # Aliases for common tools
    alias pbcopy='copy'
    alias xclip='copy'
  '';
  
  # Client: Just ensure terminal supports OSC52
  # (Kitty, iTerm2, and most modern terminals do)
}
```

#### Benefits
- Single clipboard mechanism (OSC52)
- No daemons, monitors, or sync delays
- Works with SSH, ET, and direct connections
- Zero configuration required

### Phase 3: Tmux Configuration Cleanup (Week 2)

#### Goal
Let tmux do what it does best without fighting it.

#### Simplified tmux.conf
```bash
# Simple, reliable tmux configuration
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 10000

# Status bar with devspace name
set -g status-left '#[fg=blue,bold]#S #[default]'

# Window naming - let applications set it
set -g allow-rename on
set -g automatic-rename on

# Simple key bindings
bind c new-window -c "#{pane_current_path}"
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
```

### Phase 4: Testing and Migration (Week 3)

#### Testing Plan
1. **Connection reliability**: Test from Mac, Blink, and direct SSH
2. **Session persistence**: Verify sessions survive reboots
3. **Clipboard functionality**: Test with common workflows
4. **Performance**: Ensure no delays or hangs

#### Migration Steps
1. Back up current configuration
2. Deploy simplified version to test server
3. Run in parallel for 1 week
4. Migrate primary server
5. Remove old complexity

## Success Metrics

### Quantitative
- **Code reduction**: From ~2000 lines to ~200 lines (90% reduction)
- **File count**: From 12+ files to 2-3 files
- **Dependencies**: Remove piknik, reduce shell complexity
- **Startup time**: < 1 second to create all sessions

### Qualitative
- **Reliability**: No more flaky expansions or state corruption
- **Maintainability**: Can understand entire system in 5 minutes
- **User experience**: Same simple commands, more reliable behavior

## Implementation Timeline

### Week 1
- [ ] Create simplified devspaces implementation
- [ ] Test on secondary server
- [ ] Document new architecture

### Week 2
- [ ] Extract clipboard to separate project
- [ ] Implement OSC52-only solution
- [ ] Update tmux configuration

### Week 3
- [ ] Full testing on all platforms
- [ ] Parallel running with old system
- [ ] Final migration

### Week 4
- [ ] Remove old implementation
- [ ] Update documentation
- [ ] Archive complex version for reference

## Risks and Mitigations

### Risk 1: Feature Loss
**Mitigation**: The only "features" we're losing are the complex ones that don't work reliably anyway.

### Risk 2: User Habit Change
**Mitigation**: Keep the same command interface (`earth`, `mars`, etc.) so muscle memory still works.

### Risk 3: Edge Cases
**Mitigation**: Test thoroughly on all platforms before full migration.

## Long-term Vision

Once simplified, the devspaces system should:
- Be boring and reliable (like GNU screen was)
- Require zero maintenance
- Be understandable by anyone in 5 minutes
- Serve as a foundation for 5+ years without changes

## Next Steps

1. Review this plan and adjust based on priorities
2. Create a test branch with simplified implementation
3. Begin Week 1 implementation
4. Set up testing environment on secondary server

## Conclusion

The current devspaces system tried to be too clever. By embracing simplicity and leveraging tmux's built-in capabilities, we can achieve the same user experience with 90% less code and 100% more reliability. The planetary naming scheme was a great idea - it just needs a simpler implementation.