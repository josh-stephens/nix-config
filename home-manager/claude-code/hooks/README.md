# Claude Code Hooks

This directory contains intelligent hooks that run after Claude Code modifies files, providing real-time feedback and preventing common mistakes.

## 🚀 Features

### 🎯 Smart Language Detection
The hook automatically detects your project type and runs appropriate tools:
- **Go**: `gofmt`, `golangci-lint`, plus advanced checks (forbidden patterns, import cycles, complexity analysis)
- **Python**: `black`, `ruff`/`flake8`
- **JavaScript/TypeScript**: `eslint`, `prettier`
- **Rust**: `cargo fmt`, `cargo clippy`
- **Nix**: `nixpkgs-fmt`/`alejandra`, `statix`
- **Mixed projects**: Runs appropriate tools for each detected language

### 🛡️ Go-Specific Advanced Checks
When working in Go projects, additional guardrails prevent common mistakes:
- ❌ Forbidden patterns (`time.Sleep`, `panic()`, `interface{}`)
- 🔄 Import cycle detection
- 📝 Godoc coverage for exported items
- 🛡️ SQL injection pattern detection
- 🧠 Cognitive complexity limits
- 🖨️ Direct print statement detection
- 📤 Naked return detection

### ⚡ Performance Optimizations
- **Smart file filtering**: Only checks modified files when possible
- **Configurable limits**: Prevent runaway on huge repos
- **Fast mode**: Skip slow checks with `--fast` flag

### 🔔 Notifications
- Sends notifications via ntfy when Claude finishes
- Includes terminal context for easy identification
- Rate limited to prevent spam

## 📦 Installation

These hooks are automatically installed by Nix home-manager to `~/.claude/hooks/`

## ⚙️ Configuration

### Global Settings
Override via environment variables or project-specific `.claude-hooks-config.sh`:

```bash
# Disable all hooks
export CLAUDE_HOOKS_ENABLED=false

# Enable debug mode
export CLAUDE_HOOKS_DEBUG=1

# Skip slow checks
./smart-lint.sh --fast
```

### Per-Project Settings
Create `.claude-hooks-config.sh` in your project root:

```bash
# Disable specific checks for this project
export CLAUDE_HOOKS_GO_PRINT_STATEMENTS=false
export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=30

# Disable Go checks entirely
export CLAUDE_HOOKS_GO_ENABLED=false

# See example-claude-hooks-config.sh for more options
```

### Excluding Files
Create `.claude-hooks-ignore` in your project root:

```gitignore
# Vendor directories
vendor/**
node_modules/**

# Generated files
*.pb.go
*_generated.go

# See example-claude-hooks-ignore for more patterns
```

### Inline Disabling
Add to the top of any file to skip hooks:

```go
// claude-hooks-disable
```

## 🔧 Command Line Usage

```bash
# Normal usage (called automatically by Claude)
./smart-lint.sh

# Debug mode
./smart-lint.sh --debug

# Fast mode (skip slow checks)
./smart-lint.sh --fast
```

## 📊 How It Works

1. After any `Write`, `Edit`, `MultiEdit`, or `Update` operation:
   - `smart-lint.sh` runs, detecting project type and running appropriate checks
   - Results are summarized showing all issues that must be fixed

2. Exit codes:
   - `0`: All checks passed - everything is ✅ GREEN
   - `1`: General error (missing dependencies, etc.) 
   - `2`: ANY issues found - ALL must be fixed (no warnings, everything is an error)

3. Performance features:
   - Fast mode available to skip slow checks
   - Smart filtering to only check modified files

## 🐛 Troubleshooting

### Hooks running too slowly?
```bash
# Use fast mode
export CLAUDE_HOOKS_FAIL_FAST=true

# Skip expensive checks
export CLAUDE_HOOKS_GO_IMPORT_CYCLES=false

# Reduce file limit for large repos
export CLAUDE_HOOKS_MAX_FILES=500
```

### False positives?
- Check for allowed exceptions (e.g., `main.go` can use `time.Sleep`)
- Use `.claude-hooks-ignore` to exclude specific files
- Adjust thresholds in `.claude-hooks-config.sh`

### Need to debug?
```bash
# Enable debug output
export CLAUDE_HOOKS_DEBUG=1

# Run hooks manually
cd /your/project
~/.claude/hooks/smart-lint.sh --debug
```

## 🔌 Dependencies

The hooks work best with these optional tools installed:

### Go
- `go`: Basic Go toolchain
- `gofmt`: Code formatting (included with Go)
- `golangci-lint`: Comprehensive linting
- `gocognit`: Complexity analysis

### Python
- `black`: Code formatting
- `ruff`: Fast linting
- `flake8`: Traditional linting (fallback)

### JavaScript/TypeScript
- `npm`/`npx`: Package management
- `eslint`: Linting (via package.json)
- `prettier`: Code formatting

### Rust
- `cargo`: Rust toolchain
- `rustfmt`: Code formatting
- `clippy`: Linting

### Nix
- `nixpkgs-fmt` or `alejandra`: Code formatting
- `statix`: Static analysis

The hooks gracefully degrade if tools aren't installed.

## 🎨 Customization

### Custom Project Hooks
Add to `.claude-hooks-config.sh`:
```bash
# Override specific settings
export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=30
export CLAUDE_HOOKS_PYTHON_ENABLED=false
```

## 📈 Future Improvements
- JSON/YAML configuration instead of shell variables
- Language server protocol integration
- Incremental checking (only modified lines)
- More language support (C++, Java, etc.)