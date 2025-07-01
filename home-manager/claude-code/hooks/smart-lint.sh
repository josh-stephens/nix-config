#!/usr/bin/env bash
# smart-lint.sh - Intelligent project-aware linting hook for Claude Code
#
# SYNOPSIS
#   smart-lint.sh [options]
#
# DESCRIPTION
#   Automatically detects project type and runs appropriate formatting/linting
#   tools after Claude Code modifies files. Supports Go, Python, JavaScript/
#   TypeScript, Rust, and Nix projects.
#
# OPTIONS
#   --debug       Enable debug output
#
# EXIT CODES
#   0 - Success (all checks passed)
#   1 - General error (missing dependencies, etc.)
#   2 - Linting/formatting errors that block commit
#
# CONFIGURATION
#   See config.sh for available options. Project-specific overrides can be
#   placed in .claude-hooks-config.sh in the project root.
#
# EXAMPLES
#   # Run normally (called by Claude hooks)
#   ./smart-lint.sh
#
#   # Debug mode
#   CLAUDE_HOOKS_DEBUG=1 ./smart-lint.sh
#
#   # Disable specific checks for a project
#   echo "export CLAUDE_HOOKS_GO_ENABLED=false" > .claude-hooks-config.sh

set -e

# Load shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/hooks-lib.sh"

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            export CLAUDE_HOOKS_DEBUG=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load configuration
load_config

# Start timing
START_TIME=$(time_start)

# Detect project type
PROJECT_TYPE=$(detect_project_type)
log_info "Project type: $PROJECT_TYPE"

# Function to run Go linting
lint_go() {
    if [[ "${CLAUDE_HOOKS_GO_ENABLED:-true}" != "true" ]]; then
        log_debug "Go linting disabled"
        return 0
    fi
    
    log_info "Running Go linters..."
    
    # Check if Makefile exists with fmt and lint targets
    if [[ -f "Makefile" ]]; then
        local has_fmt=$(grep -E "^fmt:" Makefile 2>/dev/null || echo "")
        local has_lint=$(grep -E "^lint:" Makefile 2>/dev/null || echo "")
        
        if [[ -n "$has_fmt" && -n "$has_lint" ]]; then
            log_info "Using Makefile targets"
            
            show_progress "Running make fmt"
            if ! make fmt >/dev/null 2>&1; then
                clear_progress
                add_summary "error" "Go formatting failed (make fmt)"
                return 2
            fi
            clear_progress
            add_summary "success" "Go code formatted"
            
            show_progress "Running make lint"
            if ! make lint 2>&1; then
                clear_progress
                add_summary "error" "Go linting failed (make lint)"
                return 2
            fi
            clear_progress
            add_summary "success" "Go linting passed"
            return 0
        fi
    fi
    
    # Fallback to direct commands
    log_info "Using direct Go tools"
    
    # Format check
    show_progress "Checking Go formatting"
    local unformatted_files=$(gofmt -l . 2>/dev/null | grep -v vendor/ || true)
    clear_progress
    
    if [[ -n "$unformatted_files" ]]; then
        log_warn "Formatting Go files..."
        gofmt -w .
        add_summary "warning" "Go files were reformatted"
    else
        add_summary "success" "Go formatting correct"
    fi
    
    # Linting
    if command_exists golangci-lint; then
        show_progress "Running golangci-lint"
        if ! golangci-lint run --timeout=2m 2>&1; then
            clear_progress
            add_summary "error" "golangci-lint found issues"
            return 2
        fi
        clear_progress
        add_summary "success" "golangci-lint passed"
    elif command_exists go; then
        show_progress "Running go vet"
        if ! go vet ./... 2>&1; then
            clear_progress
            add_summary "error" "go vet found issues"
            return 2
        fi
        clear_progress
        add_summary "success" "go vet passed"
    else
        log_warn "No Go linting tools available"
    fi
    
    return 0
}

# Function to run Python linting
lint_python() {
    if [[ "${CLAUDE_HOOKS_PYTHON_ENABLED:-true}" != "true" ]]; then
        log_debug "Python linting disabled"
        return 0
    fi
    
    log_info "Running Python linters..."
    
    # Black formatting
    if command_exists black; then
        show_progress "Running black formatter"
        if black . --check --quiet 2>/dev/null; then
            clear_progress
            add_summary "success" "Python formatting correct"
        else
            black . --quiet 2>/dev/null
            clear_progress
            add_summary "warning" "Python files were reformatted"
        fi
    fi
    
    # Linting
    if command_exists ruff; then
        show_progress "Running ruff"
        if ! ruff check --fix . 2>&1; then
            clear_progress
            add_summary "warning" "Ruff found and fixed issues"
        else
            clear_progress
            add_summary "success" "Ruff check passed"
        fi
    elif command_exists flake8; then
        show_progress "Running flake8"
        if flake8 . 2>&1; then
            clear_progress
            add_summary "success" "Flake8 check passed"
        else
            clear_progress
            add_summary "warning" "Flake8 found issues"
        fi
    fi
    
    return 0
}

# Function to run JavaScript/TypeScript linting
lint_javascript() {
    if [[ "${CLAUDE_HOOKS_JS_ENABLED:-true}" != "true" ]]; then
        log_debug "JavaScript linting disabled"
        return 0
    fi
    
    log_info "Running JavaScript/TypeScript linters..."
    
    # Check for ESLint
    if [[ -f "package.json" ]] && grep -q "eslint" package.json 2>/dev/null; then
        if command_exists npm; then
            show_progress "Running ESLint"
            if npm run lint --if-present 2>&1; then
                clear_progress
                add_summary "success" "ESLint check passed"
            else
                clear_progress
                add_summary "warning" "ESLint found issues"
            fi
        fi
    fi
    
    # Prettier
    if [[ -f ".prettierrc" ]] || [[ -f "prettier.config.js" ]] || [[ -f ".prettierrc.json" ]]; then
        if command_exists prettier; then
            show_progress "Running Prettier"
            if prettier --check . 2>/dev/null; then
                clear_progress
                add_summary "success" "Prettier formatting correct"
            else
                prettier --write . 2>/dev/null
                clear_progress
                add_summary "warning" "Files were reformatted with Prettier"
            fi
        elif command_exists npx; then
            show_progress "Running Prettier via npx"
            if npx prettier --check . 2>/dev/null; then
                clear_progress
                add_summary "success" "Prettier formatting correct"
            else
                npx prettier --write . 2>/dev/null
                clear_progress
                add_summary "warning" "Files were reformatted with Prettier"
            fi
        fi
    fi
    
    return 0
}

# Function to run Rust linting
lint_rust() {
    if [[ "${CLAUDE_HOOKS_RUST_ENABLED:-true}" != "true" ]]; then
        log_debug "Rust linting disabled"
        return 0
    fi
    
    log_info "Running Rust linters..."
    
    if command_exists cargo; then
        show_progress "Running cargo fmt"
        if cargo fmt -- --check 2>/dev/null; then
            clear_progress
            add_summary "success" "Rust formatting correct"
        else
            cargo fmt 2>/dev/null
            clear_progress
            add_summary "warning" "Rust files were reformatted"
        fi
        
        show_progress "Running cargo clippy"
        if cargo clippy --quiet -- -D warnings 2>&1; then
            clear_progress
            add_summary "success" "Clippy check passed"
        else
            clear_progress
            add_summary "warning" "Clippy found issues"
        fi
    else
        log_warn "Cargo not found, skipping Rust checks"
    fi
    
    return 0
}

# Function to run Nix linting
lint_nix() {
    if [[ "${CLAUDE_HOOKS_NIX_ENABLED:-true}" != "true" ]]; then
        log_debug "Nix linting disabled"
        return 0
    fi
    
    log_info "Running Nix linters..."
    
    # Find all .nix files
    local nix_files=$(find . -name "*.nix" -type f | grep -v -E "(result/|/nix/store/)" | head -20)
    
    if [[ -z "$nix_files" ]]; then
        log_debug "No Nix files found"
        return 0
    fi
    
    # Check formatting with nixpkgs-fmt or alejandra
    if command_exists nixpkgs-fmt; then
        show_progress "Running nixpkgs-fmt"
        if echo "$nix_files" | xargs nixpkgs-fmt --check 2>/dev/null; then
            clear_progress
            add_summary "success" "Nix formatting correct"
        else
            echo "$nix_files" | xargs nixpkgs-fmt 2>/dev/null
            clear_progress
            add_summary "warning" "Nix files were reformatted"
        fi
    elif command_exists alejandra; then
        show_progress "Running alejandra"
        if echo "$nix_files" | xargs alejandra --check 2>/dev/null; then
            clear_progress
            add_summary "success" "Nix formatting correct"
        else
            echo "$nix_files" | xargs alejandra --quiet 2>/dev/null
            clear_progress
            add_summary "warning" "Nix files were reformatted"
        fi
    fi
    
    # Static analysis with statix
    if command_exists statix; then
        show_progress "Running statix"
        if statix check 2>&1; then
            clear_progress
            add_summary "success" "Statix check passed"
        else
            clear_progress
            add_summary "warning" "Statix found issues"
        fi
    fi
    
    return 0
}

# Main execution
main() {
    local exit_code=0
    
    # Handle mixed project types
    if [[ "$PROJECT_TYPE" == mixed:* ]]; then
        local types="${PROJECT_TYPE#mixed:}"
        IFS=',' read -ra TYPE_ARRAY <<< "$types"
        
        for type in "${TYPE_ARRAY[@]}"; do
            case "$type" in
                "go") lint_go || exit_code=$? ;;
                "python") lint_python || exit_code=$? ;;
                "javascript") lint_javascript || exit_code=$? ;;
                "rust") lint_rust || exit_code=$? ;;
                "nix") lint_nix || exit_code=$? ;;
            esac
            
            # Fail fast if configured
            if [[ "$CLAUDE_HOOKS_FAIL_FAST" == "true" && $exit_code -ne 0 ]]; then
                break
            fi
        done
    else
        # Single project type
        case "$PROJECT_TYPE" in
            "go") lint_go || exit_code=$? ;;
            "python") lint_python || exit_code=$? ;;
            "javascript") lint_javascript || exit_code=$? ;;
            "rust") lint_rust || exit_code=$? ;;
            "nix") lint_nix || exit_code=$? ;;
            "unknown") 
                log_info "No recognized project type, skipping checks"
                ;;
        esac
    fi
    
    # Show timing if enabled
    time_end "$START_TIME"
    
    # Print summary
    print_summary
    
    # Return appropriate exit code
    if [[ $exit_code -eq 2 || $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
        return 2  # Blocking errors
    elif [[ $CLAUDE_HOOKS_WARNING_COUNT -gt 0 ]]; then
        return 0  # Non-blocking warnings
    else
        return 0  # Success
    fi
}

# Run main function
main