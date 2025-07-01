#!/usr/bin/env bash
# hooks-lib.sh - Shared library for Claude Code hooks
#
# This library provides common functionality used across all Claude hooks:
# - Standardized color output
# - Logging and debugging
# - Performance optimizations via caching
# - Error handling utilities
# - Project type detection

# Enable strict error handling
set -euo pipefail

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Debug mode - set CLAUDE_HOOKS_DEBUG=1 to enable
CLAUDE_HOOKS_DEBUG="${CLAUDE_HOOKS_DEBUG:-0}"

# Logging functions
log_debug() {
    [[ "$CLAUDE_HOOKS_DEBUG" == "1" ]] && echo -e "${CYAN}[DEBUG]${NC} $*" >&2
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*" >&2
}

# Performance timing
time_start() {
    if [[ "$CLAUDE_HOOKS_DEBUG" == "1" ]]; then
        echo $(($(date +%s%N)/1000000))
    fi
}

time_end() {
    if [[ "$CLAUDE_HOOKS_DEBUG" == "1" ]]; then
        local start=$1
        local end=$(($(date +%s%N)/1000000))
        local duration=$((end - start))
        log_debug "Execution time: ${duration}ms"
    fi
}

# Project type detection
detect_project_type() {
    local project_type="unknown"
    
    # Check for multiple project types (could be mixed)
    local types=()
    
    # Go project
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]] || [[ -n "$(find . -maxdepth 3 -name "*.go" -type f -print -quit 2>/dev/null)" ]]; then
        types+=("go")
    fi
    
    # Python project
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]] || [[ -n "$(find . -maxdepth 3 -name "*.py" -type f -print -quit 2>/dev/null)" ]]; then
        types+=("python")
    fi
    
    # JavaScript/TypeScript project
    if [[ -f "package.json" ]] || [[ -f "tsconfig.json" ]] || [[ -n "$(find . -maxdepth 3 \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) -type f -print -quit 2>/dev/null)" ]]; then
        types+=("javascript")
    fi
    
    # Rust project
    if [[ -f "Cargo.toml" ]] || [[ -n "$(find . -maxdepth 3 -name "*.rs" -type f -print -quit 2>/dev/null)" ]]; then
        types+=("rust")
    fi
    
    # Nix project
    if [[ -f "flake.nix" ]] || [[ -f "default.nix" ]] || [[ -f "shell.nix" ]]; then
        types+=("nix")
    fi
    
    # Return primary type or "mixed" if multiple
    if [[ ${#types[@]} -eq 1 ]]; then
        project_type="${types[0]}"
    elif [[ ${#types[@]} -gt 1 ]]; then
        project_type="mixed:$(IFS=,; echo "${types[*]}")"
    fi
    
    log_debug "Detected project type: $project_type"
    echo "$project_type"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get list of modified files (if available from git)
get_modified_files() {
    if [[ -d .git ]] && command_exists git; then
        # Get files modified in the last commit or currently staged/modified
        git diff --name-only HEAD 2>/dev/null || true
        git diff --cached --name-only 2>/dev/null || true
    fi
}

# Check if we should skip a file based on ignore patterns
should_skip_file() {
    local file="$1"
    
    # Check .claude-hooks-ignore if it exists
    if [[ -f ".claude-hooks-ignore" ]]; then
        while IFS= read -r pattern; do
            # Skip comments and empty lines
            [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
            
            # Check if file matches pattern
            if [[ "$file" == $pattern ]]; then
                log_debug "Skipping $file due to .claude-hooks-ignore pattern: $pattern"
                return 0
            fi
        done < ".claude-hooks-ignore"
    fi
    
    # Check for inline skip comments
    if [[ -f "$file" ]] && head -n 5 "$file" 2>/dev/null | grep -q "claude-hooks-disable"; then
        log_debug "Skipping $file due to inline claude-hooks-disable comment"
        return 0
    fi
    
    return 1
}

# Load configuration with defaults
load_config() {
    # Default configuration
    export CLAUDE_HOOKS_ENABLED="${CLAUDE_HOOKS_ENABLED:-true}"
    export CLAUDE_HOOKS_FAIL_FAST="${CLAUDE_HOOKS_FAIL_FAST:-false}"
    export CLAUDE_HOOKS_SHOW_TIMING="${CLAUDE_HOOKS_SHOW_TIMING:-false}"
    
    # Source config.sh for compatibility
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "$script_dir/config.sh" ]] && source "$script_dir/config.sh"
    
    # Project-specific overrides
    [[ -f ".claude-hooks-config.sh" ]] && source ".claude-hooks-config.sh"
    
    # Quick exit if hooks are disabled
    if [[ "$CLAUDE_HOOKS_ENABLED" != "true" ]]; then
        log_info "Claude hooks are disabled"
        exit 0
    fi
}

# Progress indicator for long operations
show_progress() {
    local message="$1"
    if [[ -t 2 ]]; then  # Only if stderr is a terminal
        printf "\r${BLUE}⏳${NC} %s..." "$message" >&2
    fi
}

clear_progress() {
    if [[ -t 2 ]]; then
        printf "\r\033[K" >&2  # Clear line
    fi
}

# Summary tracking
declare -a CLAUDE_HOOKS_SUMMARY=()
declare -i CLAUDE_HOOKS_ERROR_COUNT=0
declare -i CLAUDE_HOOKS_WARNING_COUNT=0

add_summary() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "error")
            CLAUDE_HOOKS_ERROR_COUNT+=1
            CLAUDE_HOOKS_SUMMARY+=("${RED}❌${NC} $message")
            ;;
        "warning")
            CLAUDE_HOOKS_WARNING_COUNT+=1
            CLAUDE_HOOKS_SUMMARY+=("${YELLOW}⚠️${NC}  $message")
            ;;
        "success")
            CLAUDE_HOOKS_SUMMARY+=("${GREEN}✅${NC} $message")
            ;;
        *)
            CLAUDE_HOOKS_SUMMARY+=("$message")
            ;;
    esac
}

print_summary() {
    if [[ ${#CLAUDE_HOOKS_SUMMARY[@]} -gt 0 ]]; then
        echo -e "\n${BLUE}═══ Hook Summary ═══${NC}"
        for item in "${CLAUDE_HOOKS_SUMMARY[@]}"; do
            echo -e "$item"
        done
        
        if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
            echo -e "\n${RED}Total errors: $CLAUDE_HOOKS_ERROR_COUNT${NC}"
        fi
        if [[ $CLAUDE_HOOKS_WARNING_COUNT -gt 0 ]]; then
            echo -e "${YELLOW}Total warnings: $CLAUDE_HOOKS_WARNING_COUNT${NC}"
        fi
    fi
}

# Cleanup function
cleanup() {
    clear_progress
}

# Set up trap for cleanup
trap cleanup EXIT

# Export functions for use in other scripts
export -f log_debug log_info log_warn log_error log_success
export -f time_start time_end
export -f detect_project_type command_exists
export -f get_modified_files should_skip_file
export -f load_config show_progress clear_progress
export -f add_summary print_summary