#!/usr/bin/env bash
# config.sh - Configuration for Claude Code hooks
#
# DESCRIPTION
#   Central configuration file for all Claude Code hooks. Sets default
#   values that can be overridden by project-specific .claude-hooks-config.sh
#   files or environment variables.
#
# USAGE
#   This file is automatically sourced by hooks via hooks-lib.sh.
#   To override settings:
#   
#   1. Environment variables (highest priority):
#      CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD=30 claude
#   
#   2. Project-specific config (medium priority):
#      echo "export CLAUDE_HOOKS_GO_ENABLED=false" > .claude-hooks-config.sh
#   
#   3. This file (lowest priority)
#
# CONFIGURATION VARIABLES
#   See below for all available settings with descriptions.

# ============================================================================
# GLOBAL SETTINGS
# ============================================================================

# Master switch - set to false to disable all hooks
export CLAUDE_HOOKS_ENABLED="${CLAUDE_HOOKS_ENABLED:-true}"

# Fail on first error instead of running all checks
export CLAUDE_HOOKS_FAIL_FAST="${CLAUDE_HOOKS_FAIL_FAST:-false}"

# Show execution timing for performance debugging
export CLAUDE_HOOKS_SHOW_TIMING="${CLAUDE_HOOKS_SHOW_TIMING:-false}"

# Debug mode - enables verbose output
export CLAUDE_HOOKS_DEBUG="${CLAUDE_HOOKS_DEBUG:-0}"

# ============================================================================
# LANGUAGE-SPECIFIC ENABLES
# ============================================================================

# Enable/disable checks for specific languages
export CLAUDE_HOOKS_GO_ENABLED="${CLAUDE_HOOKS_GO_ENABLED:-true}"
export CLAUDE_HOOKS_PYTHON_ENABLED="${CLAUDE_HOOKS_PYTHON_ENABLED:-true}"
export CLAUDE_HOOKS_JS_ENABLED="${CLAUDE_HOOKS_JS_ENABLED:-true}"
export CLAUDE_HOOKS_RUST_ENABLED="${CLAUDE_HOOKS_RUST_ENABLED:-true}"
export CLAUDE_HOOKS_NIX_ENABLED="${CLAUDE_HOOKS_NIX_ENABLED:-true}"

# ============================================================================
# GO-SPECIFIC SETTINGS
# ============================================================================

# Master switch for Go guardrails (separate from basic linting)
export CLAUDE_HOOKS_GO_GUARDRAILS="${CLAUDE_HOOKS_GO_GUARDRAILS:-true}"

# Individual Go checks
export CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS="${CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS:-true}"
export CLAUDE_HOOKS_GO_IMPORT_CYCLES="${CLAUDE_HOOKS_GO_IMPORT_CYCLES:-true}"
export CLAUDE_HOOKS_GO_GODOC_CHECK="${CLAUDE_HOOKS_GO_GODOC_CHECK:-true}"
export CLAUDE_HOOKS_GO_SQL_INJECTION="${CLAUDE_HOOKS_GO_SQL_INJECTION:-true}"
export CLAUDE_HOOKS_GO_COMPLEXITY="${CLAUDE_HOOKS_GO_COMPLEXITY:-true}"
export CLAUDE_HOOKS_GO_PRINT_STATEMENTS="${CLAUDE_HOOKS_GO_PRINT_STATEMENTS:-true}"
export CLAUDE_HOOKS_GO_SECURITY_SCAN="${CLAUDE_HOOKS_GO_SECURITY_SCAN:-true}"
export CLAUDE_HOOKS_GO_NAKED_RETURNS="${CLAUDE_HOOKS_GO_NAKED_RETURNS:-true}"
export CLAUDE_HOOKS_GO_TODO_CHECK="${CLAUDE_HOOKS_GO_TODO_CHECK:-false}"  # Off by default

# Go thresholds and limits
export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD="${CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD:-20}"
export CLAUDE_HOOKS_GO_MAX_FUNC_LINES="${CLAUDE_HOOKS_GO_MAX_FUNC_LINES:-50}"
export CLAUDE_HOOKS_GO_MAX_FILE_LINES="${CLAUDE_HOOKS_GO_MAX_FILE_LINES:-500}"

# ============================================================================
# NOTIFICATION SETTINGS
# ============================================================================

# Enable/disable ntfy notifications
export CLAUDE_HOOKS_NTFY_ENABLED="${CLAUDE_HOOKS_NTFY_ENABLED:-true}"

# Custom config file location (defaults to ~/.config/claude-code-ntfy/config.yaml)
export CLAUDE_HOOKS_NTFY_CONFIG="${CLAUDE_HOOKS_NTFY_CONFIG:-}"

# ============================================================================
# PERFORMANCE SETTINGS
# ============================================================================

# Maximum number of files to check (prevent runaway on huge repos)
export CLAUDE_HOOKS_MAX_FILES="${CLAUDE_HOOKS_MAX_FILES:-1000}"

# ============================================================================
# PROJECT-SPECIFIC OVERRIDES
# ============================================================================

# Source project-specific configuration if it exists
# This allows per-project customization without modifying global config
if [[ -f ".claude-hooks-config.sh" ]]; then
    # shellcheck source=/dev/null
    source ".claude-hooks-config.sh"
fi

# ============================================================================
# DEPRECATED SETTINGS (kept for backwards compatibility)
# ============================================================================

# None yet, but this section will hold old settings that are being phased out