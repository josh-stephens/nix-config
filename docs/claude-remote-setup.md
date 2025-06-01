# Claude Code Remote Development Setup with tmux

## Project Goal

Create a persistent remote development environment where multiple Claude Code instances can run continuously on NixOS servers, accessible from various clients (Mac, mobile, etc.) via Tailscale, without requiring constant connection or monitoring.

## Core Requirements

### 1. Persistent Development Sessions
- **5 named sessions** using planetary theme (mercury, venus, earth, mars, jupiter)
- Sessions must survive client disconnection and server reboots
- Each session should maintain its working directory and state
- Claude Code processes should continue running when no client is attached
- Push notifications from terminal bells via nfty.sh

### 2. Naming Convention & Mental Model
- **mercury** - Quick experiments, ephemeral work
- **venus** - Personal creative/web projects  
- **earth** - Primary work project (home base)
- **mars** - Secondary work project (frontier exploration)
- **jupiter** - Large personal project (the giant)

This provides natural ordering and memorable associations without requiring per-project naming.

### 3. Client Access Requirements

#### Mac (Primary Development)
- Quick keyboard shortcuts to connect to any planet (ideally Cmd+1 through Cmd+5)
- Visual indicators showing which environment is active
- Seamless connection via Tailscale SSH
- Proper terminal emulation (works well with Kitty)
- Copy/paste functionality between local and remote

#### Mobile (iOS via Blink Shell or similar)
- Simple commands to attach to sessions (e.g., type "earth" to connect)
- Readable fonts and proper touch scrolling
- Quick session switching without complex key combinations
- Ability to monitor Claude's progress without active interaction

### 4. Development Environment Structure

Each planet should support:
- **Multiple windows/panes** within each session:
  - Claude Code instance
  - Neovim for editing
  - General terminal for commands
  - Log viewing/monitoring
- **Isolated workspaces** with dedicated directories
- **Project context** preservation between connections
- **Easy setup** via shell commands (`earth .`, `venus /path/to/workdir`, etc.)
- **Confirmation of teardown** if the above commands are invoked

### 5. Authentication & Credentials

#### Critical: AWS SSO Support
- Must handle AWS SSO credentials that expire
- Need mechanism to sync credentials from Mac to NixOS server
- Should support both work and personal AWS accounts
- Credentials should be available to Claude Code instances

#### Other Credentials
- Git SSH keys (via agent forwarding)
- Kubernetes contexts and configurations
- Any other development tokens/secrets

### 6. Quality of Life Features

#### Status Monitoring
- Quick command to see all planets and their current state
- Visual differentiation between environments (colors, emojis) in Starship
- Ability to see what each Claude instance is working on
- No requirement to remember what each session contains

#### Session Management
- Automatic session creation on system boot
- Graceful handling of crashed sessions
- Easy restart/reset of individual planets
- Protection against accidental session termination

#### Workflow Integration
- Should feel as natural as opening a new terminal
- Minimal cognitive overhead for switching contexts
- No need to manage session names or remember configurations
- Quick access to the right environment for the current task

## Ideal End State

### Morning Workflow
1. Open laptop, press Cmd+3
2. Immediately see Earth session with Claude Code where I left it
3. Claude has been working overnight on assigned tasks
4. Review output, provide guidance, switch to another planet
5. Open neovim in the same project with another shortcut
6. See where I am inside NeoVim itself

### Context Switching
- Press Cmd+1 to check Mercury experiment
- Press Cmd+4 to review Mars work project
- Each environment maintains its state perfectly
- No mental overhead remembering what's where

### Mobile Check-in
- Open Blink on phone while commuting
- Type "earth" to see main project progress
- Scroll through Claude's output
- Disconnect without disrupting anything

### Credential Management
- Run AWS SSO login on Mac
- Single command syncs to all planets
- All Claude instances have fresh credentials
- No manual credential management per session

### Mobile push
- At lunch, eating happily
- Claude needs my approval for a task and activates a terminal bell
- I get a push notification on my phone, informing me which planet is summoning me
- I open Blink, type "mars"
- Respond to Claude, and lock my phone

## Technical Considerations

### Why tmux?
- Provides persistent sessions that survive disconnection
- Mature, stable tool with wide support
- Built-in window management and organization
- Excellent terminal compatibility
- Native copy/paste buffer management

### Why Planets?
- Fixed set prevents proliferation of unnamed sessions
- Natural ordering (distance from sun = experiment to production)
- Memorable without being unprofessional
- Short to type
- Fun enough to stick with

### Integration Points
- Should work with existing home-manager configuration
- Must integrate with Tailscale networking
- Should complement (not replace) local development
- Must handle both NixOS and Darwin environments

## Success Criteria

1. **Zero friction**: Connecting to a planet should be as easy as opening a new terminal
2. **Perfect persistence**: Work continues exactly where you left it
3. **Clear organization**: Always know which planet has which project
4. **Credential simplicity**: One sync command handles all auth needs
5. **Mobile friendly**: Can meaningfully check progress from phone
6. **Crash resilient**: System recovers gracefully from any failure

## Anti-Requirements

- **No complex session management**: Don't make users think about session names
- **No manual tmux configuration**: Should just work out of the box
- **No credential complexity**: Don't require per-session auth setup
- **No forgotten work**: Every planet should be discoverable
- **No lost state**: Reboots shouldn't lose work

## Implementation Details

### 1. Notification System (nfty.sh)
- **Approach**: Wrapper script around Claude Code that monitors output and terminal bells
- **Triggers**:
  - Terminal bell character (^G) from Claude Code
  - Claude prints "Task completed" or similar completion messages
  - Claude asks questions (detected by "?" at end of output)
  - Claude encounters errors requiring user intervention
  - Inactivity for extended period after user request
- **Implementation**: 
  - Shell script monitoring Claude's stdout/stderr and bell characters
  - Forward all output while intercepting bells
  - Send to nfty.sh topic `CUFVGE2uFcTRl7Br` with planet name in title
  - Include brief context in notification body

### 2. Starship Integration
Building on existing Catppuccin Mocha theme:
- **Planet Indicator**: Add custom module showing current planet with colored dot and name
  - `● mercury` (all in flamingo #f2cdcd) - Quick experiments
  - `● venus` (all in pink #f5c2e7) - Personal creative projects
  - `● earth` (all in green #a6e3a1) - Primary work
  - `● mars` (all in red #f38ba8) - Secondary work  
  - `● jupiter` (all in peach #fab387) - Large personal project
- **Position**: After hostname, before git info
- **Format**: `[ ● $planet_name ]($planet_style)` where style sets foreground color
- **Detection**: Based on TMUX_PLANET environment variable

### 3. AWS SSO Credential Management
- **Primary Method**: Automated sync via dedicated command
- **Implementation**:
  - `planet-sync-aws` command on Mac that:
    - Copies `~/.aws/config` and `~/.aws/sso/cache/*` to ultraviolet
    - Uses rsync over Tailscale SSH
    - Optionally accepts planet name to sync to specific session
  - Cron job on ultraviolet to distribute to all planet sessions
- **Fallback**: Manual `aws sso login` in each planet if needed

### 4. Workspace Structure
```
~/planets/
├── mercury/     # Ephemeral experiments
├── venus/       # Personal creative projects
├── earth/       # Primary work
├── mars/        # Secondary work
└── jupiter/     # Large personal project

~/projects/      # Actual project repositories
├── work/
│   ├── main-app/
│   └── secondary-app/
└── personal/
    ├── website/
    └── big-project/
```
- Planets contain symlinks to actual projects
- Each planet has `.planet-config` with project mappings
- **Commands**:
  - `<planet> .` - Set planet to current directory
  - `<planet> /path/to/project` - Set planet to specific project
  - `<planet>` - Connect to planet with existing workspace
  - Confirmation prompt when replacing existing project

### 5. Mac Client Commands
Shell functions in zsh config:
- `mercury`, `venus`, `earth`, `mars`, `jupiter` - Connect to planet
- Each runs: `ssh -t ultraviolet 'tmux attach -t planet-<name> || tmux new -s planet-<name>'`
- Optional: `planet <name>` as generic accessor
- `planet-status` - Show all planets and current projects (via SSH)

### 6. Session Layout
Default tmux layout for each planet:
- **Window 1: Claude** - Claude Code instance
- **Window 2: Editor** - Neovim
- **Window 3: Terminal** - General commands
- **Window 4: Logs** - System logs, Claude output history
- Auto-created on first connection if missing

## Migration Path

Starting from current state (multiple Kitty tabs with local Claude Code):
1. Set up basic tmux sessions on NixOS server
2. Test with one planet (earth) for main work
3. Migrate other projects to appropriate planets
4. Add mobile access once desktop flow is solid
5. Enhance with notifications/monitoring as needed

The goal is to enhance productivity without adding complexity - the infrastructure should be invisible when it's working correctly.
