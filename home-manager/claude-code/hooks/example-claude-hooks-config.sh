#!/usr/bin/env bash
# Example .claude-hooks-config.sh - Project-specific Claude hooks configuration
#
# Copy this file to your project root as .claude-hooks-config.sh and uncomment
# the settings you want to override.
#
# This file is sourced by smart-lint.sh, so it can override any setting.

# ============================================================================
# COMMON OVERRIDES
# ============================================================================

# Disable all hooks for this project
# export CLAUDE_HOOKS_ENABLED=false

# Enable debug output for troubleshooting
# export CLAUDE_HOOKS_DEBUG=1

# Stop on first error instead of running all checks
# export CLAUDE_HOOKS_FAIL_FAST=true

# ============================================================================
# LANGUAGE-SPECIFIC OVERRIDES
# ============================================================================

# Disable checks for specific languages
# export CLAUDE_HOOKS_GO_ENABLED=false
# export CLAUDE_HOOKS_PYTHON_ENABLED=false
# export CLAUDE_HOOKS_JS_ENABLED=false
# export CLAUDE_HOOKS_RUST_ENABLED=false
# export CLAUDE_HOOKS_NIX_ENABLED=false

# ============================================================================
# GO-SPECIFIC SETTINGS
# ============================================================================

# Disable specific Go checks
# export CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS=false  # Allow time.Sleep, panic(), interface{}
# export CLAUDE_HOOKS_GO_IMPORT_CYCLES=false      # Skip slow import cycle check
# export CLAUDE_HOOKS_GO_GODOC_CHECK=false        # Skip godoc coverage check
# export CLAUDE_HOOKS_GO_SQL_INJECTION=false      # Skip SQL injection patterns
# export CLAUDE_HOOKS_GO_COMPLEXITY=false         # Skip complexity analysis
# export CLAUDE_HOOKS_GO_PRINT_STATEMENTS=false   # Allow fmt.Print statements
# export CLAUDE_HOOKS_GO_NAKED_RETURNS=false      # Skip naked return check

# Adjust Go complexity threshold (default is 20)
# export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=30

# Enable TODO/FIXME checking (off by default)
# export CLAUDE_HOOKS_GO_TODO_CHECK=true

# ============================================================================
# NOTIFICATION SETTINGS
# ============================================================================

# Disable notifications for this project
# export CLAUDE_HOOKS_NTFY_ENABLED=false

# ============================================================================
# PERFORMANCE TUNING
# ============================================================================

# Limit file checking for very large repos
# export CLAUDE_HOOKS_MAX_FILES=500

# ============================================================================
# PROJECT-SPECIFIC EXAMPLES
# ============================================================================

# Example: Different settings for different environments
# if [[ "$USER" == "ci" ]]; then
#     export CLAUDE_HOOKS_FAIL_FAST=true
#     export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=15
# fi

# Example: Disable certain checks in test directories
# if [[ "$PWD" =~ /test/ ]]; then
#     export CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS=false
# fi