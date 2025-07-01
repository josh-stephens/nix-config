#!/usr/bin/env bash
# Example .claude-hooks-config.sh - Project-specific Claude hooks configuration
#
# Copy this file to your project root as .claude-hooks-config.sh and uncomment
# the settings you want to override.
#
# This file is sourced after the global config, so it can override any setting.

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

# Disable Go checks (but keep other languages)
# export CLAUDE_HOOKS_GO_ENABLED=false

# Disable specific Go guardrails
# export CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS=false  # Allow time.Sleep, panic(), etc.
# export CLAUDE_HOOKS_GO_IMPORT_CYCLES=false      # Skip slow import cycle check
# export CLAUDE_HOOKS_GO_SECURITY_SCAN=false      # Skip gosec scan

# Adjust Go complexity threshold for complex projects
# export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=30  # Default is 20

# Enable TODO/FIXME checking (off by default)
# export CLAUDE_HOOKS_GO_TODO_CHECK=true

# ============================================================================
# NOTIFICATION OVERRIDES
# ============================================================================

# Disable notifications for this project
# export CLAUDE_HOOKS_NTFY_ENABLED=false

# Use a different ntfy config file
# export CLAUDE_HOOKS_NTFY_CONFIG="$HOME/.config/my-project/ntfy.yaml"

# ============================================================================
# PERFORMANCE TUNING
# ============================================================================

# Limit file checking for very large repos
# export CLAUDE_HOOKS_MAX_FILES=500

# ============================================================================
# PROJECT-SPECIFIC PATTERNS
# ============================================================================

# Example: Allow specific patterns in certain files
# if [[ "$CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS" == "true" ]]; then
#     # Custom logic to allow patterns in specific contexts
#     # This runs after the default checks
# fi

# ============================================================================
# CUSTOM HOOKS
# ============================================================================

# Add custom checks that run after the standard hooks
# custom_post_hook() {
#     echo "Running custom project checks..."
#     # Add your custom validation here
# }
#
# Run custom hook if function exists
# if declare -f custom_post_hook > /dev/null; then
#     custom_post_hook
# fi