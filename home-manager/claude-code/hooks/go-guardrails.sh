#!/usr/bin/env bash
# go-guardrails.sh - Advanced Go-specific checks for Claude Code
#
# SYNOPSIS
#   go-guardrails.sh [options]
#
# DESCRIPTION
#   Performs advanced Go-specific checks beyond standard linting to catch
#   common antipatterns and ensure code quality. Only runs when in a Go
#   project. Checks include forbidden patterns, import cycles, documentation,
#   SQL injection detection, complexity analysis, and security scanning.
#
# OPTIONS
#   --debug       Enable debug output
#   --fast        Skip slow checks (security scan, import cycles)
#
# EXIT CODES
#   0 - Success (all checks passed or only warnings)
#   1 - General error
#   2 - Blocking errors found (forbidden patterns, import cycles, etc.)
#
# CONFIGURATION
#   See config.sh for available options. Can be disabled entirely with:
#   export CLAUDE_HOOKS_GO_GUARDRAILS=false
#
# FORBIDDEN PATTERNS
#   - time.Sleep (except in main.go)
#   - panic() calls (except in panic handlers)
#   - interface{} usage
#   - Direct fmt.Print (use structured logging)
#
# EXAMPLES
#   # Normal usage (called by Claude hooks)
#   ./go-guardrails.sh
#
#   # Fast mode (skip slow checks)
#   ./go-guardrails.sh --fast
#
#   # Disable specific check for a file
#   // claude-hooks-disable: forbidden-patterns

set -e

# Load shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/hooks-lib.sh"

# Configuration defaults
FAST_MODE=false

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            export CLAUDE_HOOKS_DEBUG=1
            shift
            ;;
        --fast)
            FAST_MODE=true
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

# Check if this is a Go project
PROJECT_TYPE=$(detect_project_type)
if [[ "$PROJECT_TYPE" != "go" && "$PROJECT_TYPE" != mixed:*go* ]]; then
    log_debug "Not a Go project, skipping Go guardrails"
    exit 0
fi

# Check if Go guardrails are enabled
if [[ "${CLAUDE_HOOKS_GO_GUARDRAILS:-true}" != "true" ]]; then
    log_info "Go guardrails disabled"
    exit 0
fi

# Start timing
START_TIME=$(time_start)

log_info "Running Go guardrails..."

# Track if we found any blocking issues
BLOCKING_ISSUES=0

# Function to check a specific pattern in files
check_pattern() {
    local pattern="$1"
    local description="$2"
    local exclude_pattern="${3:-}"
    local is_blocking="${4:-true}"
    
    show_progress "Checking for $description"
    
    local results=""
    if [[ -n "$exclude_pattern" ]]; then
        results=$(rg "$pattern" --type go --glob '!*_test.go' 2>/dev/null | grep -v "$exclude_pattern" | head -10 || true)
    else
        results=$(rg "$pattern" --type go --glob '!*_test.go' 2>/dev/null | head -10 || true)
    fi
    
    clear_progress
    
    if [[ -n "$results" ]]; then
        if [[ "$is_blocking" == "true" ]]; then
            add_summary "error" "$description detected"
            log_error "$description detected:"
            echo "$results" | while IFS= read -r line; do
                echo "  $line"
            done
            BLOCKING_ISSUES=$((BLOCKING_ISSUES + 1))
        else
            add_summary "warning" "$description detected"
            log_warn "$description detected"
        fi
        return 1
    else
        add_summary "success" "No $description found"
        return 0
    fi
}

# 1. Check for forbidden patterns
if [[ "${CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS:-true}" == "true" ]]; then
    # Check for time.Sleep (excluding main.go and test files)
    show_progress "Checking for time.Sleep usage"
    SLEEP_USAGE=$(rg 'time\.Sleep' --type go --glob '!*_test.go' --glob '!**/main.go' 2>/dev/null | grep -v "// nosec" | head -10 || true)
    clear_progress
    
    if [[ -n "$SLEEP_USAGE" ]]; then
        add_summary "error" "time.Sleep usage detected (use channels for synchronization)"
        log_error "Forbidden pattern: time.Sleep found (use channels instead):"
        echo "$SLEEP_USAGE" | while IFS= read -r line; do
            echo "  $line"
        done
        BLOCKING_ISSUES=$((BLOCKING_ISSUES + 1))
    else
        add_summary "success" "No time.Sleep usage found"
    fi
    
    # Check for panic calls (excluding panic handlers)
    check_pattern 'panic\(' "panic() calls" "panic.*\.go|// nosec"
    
    # Check for interface{} usage
    check_pattern '\binterface\{\}' "interface{} usage" "// nosec|comment"
fi

# 2. Check for import cycles (slow, can be skipped in fast mode)
if [[ "${CLAUDE_HOOKS_GO_IMPORT_CYCLES:-true}" == "true" && "$FAST_MODE" != "true" ]]; then
    show_progress "Checking for import cycles"
    
    IMPORT_CYCLE_RESULT=$(go list -f '{{join .Deps "\n"}}' ./... 2>&1 | xargs go list -f '{{if .Error}}{{.Error}}{{end}}' 2>&1 | grep -i 'import cycle' || echo "")
    
    clear_progress
    
    if [[ -n "$IMPORT_CYCLE_RESULT" ]]; then
        add_summary "error" "Import cycle detected"
        log_error "Import cycle detected:"
        echo "$IMPORT_CYCLE_RESULT"
        BLOCKING_ISSUES=$((BLOCKING_ISSUES + 1))
    else
        add_summary "success" "No import cycles found"
    fi
fi

# 3. Check for missing godoc on exported items
if [[ "${CLAUDE_HOOKS_GO_GODOC_CHECK:-true}" == "true" ]]; then
    show_progress "Checking exported items documentation"
    
    # Use a more efficient approach - check specific files that were modified
    MODIFIED_GO_FILES=$(get_modified_files | grep '\.go$' | grep -v '_test\.go' || true)
    
    if [[ -n "$MODIFIED_GO_FILES" ]]; then
        MISSING_DOCS=0
        while IFS= read -r file; do
            if [[ -f "$file" ]] && ! should_skip_file "$file"; then
                # Check for exported functions/types without docs
                if grep -E '^(func|type|const|var) [A-Z]' "$file" | grep -v '^//' >/dev/null 2>&1; then
                    MISSING_DOCS=$((MISSING_DOCS + 1))
                fi
            fi
        done <<< "$MODIFIED_GO_FILES"
        
        if [[ $MISSING_DOCS -gt 0 ]]; then
            add_summary "warning" "Some exported items missing documentation ($MISSING_DOCS files)"
        else
            add_summary "success" "Exported items have documentation"
        fi
    fi
    
    clear_progress
fi

# 4. Check for potential SQL injection
if [[ "${CLAUDE_HOOKS_GO_SQL_INJECTION:-true}" == "true" ]]; then
    # First check if database/sql is even imported
    if rg -q 'database/sql' --type go 2>/dev/null; then
        check_pattern 'fmt\.Sprintf.*(?:SELECT|INSERT|UPDATE|DELETE|WHERE)' "SQL injection patterns" "" "true"
        
        # Also check for string concatenation with SQL
        check_pattern '\+.*(?:SELECT|INSERT|UPDATE|DELETE|WHERE)' "SQL string concatenation" "" "false"
    else
        log_debug "No database/sql usage found, skipping SQL injection checks"
    fi
fi

# 5. Check complexity (if gocognit is available)
if [[ "${CLAUDE_HOOKS_GO_COMPLEXITY:-true}" == "true" ]] && command_exists gocognit; then
    show_progress "Checking cognitive complexity"
    
    COMPLEXITY_THRESHOLD="${CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD:-20}"
    COMPLEX_FUNCTIONS=$(gocognit -over "$COMPLEXITY_THRESHOLD" -top 5 . 2>/dev/null | head -10 || true)
    
    clear_progress
    
    if [[ -n "$COMPLEX_FUNCTIONS" ]]; then
        add_summary "warning" "Functions with high complexity found"
        log_warn "Functions exceeding complexity threshold ($COMPLEXITY_THRESHOLD):"
        echo "$COMPLEX_FUNCTIONS"
    else
        add_summary "success" "All functions within complexity limits"
    fi
fi

# 6. Check for direct fmt.Print usage
if [[ "${CLAUDE_HOOKS_GO_PRINT_STATEMENTS:-true}" == "true" ]]; then
    check_pattern 'fmt\.Print' "direct print statements" "cmd/.*/main\.go" "false"
fi

# 7. Security scan with gosec (slow, can be skipped in fast mode)
if [[ "${CLAUDE_HOOKS_GO_SECURITY_SCAN:-true}" == "true" && "$FAST_MODE" != "true" ]] && command_exists gosec; then
    show_progress "Running security scan"
    
    # Run gosec with specific confidence level
    GOSEC_ISSUES=$(gosec -quiet -confidence medium -fmt json ./... 2>/dev/null | jq -r '.Issues | length' 2>/dev/null || echo "0")
    
    clear_progress
    
    if [[ "$GOSEC_ISSUES" != "0" && -n "$GOSEC_ISSUES" ]]; then
        add_summary "warning" "Security issues found ($GOSEC_ISSUES)"
        log_warn "Security scan found $GOSEC_ISSUES issues - run 'gosec ./...' for details"
    else
        add_summary "success" "Security scan passed"
    fi
fi

# 8. Check for naked returns in long functions
if [[ "${CLAUDE_HOOKS_GO_NAKED_RETURNS:-true}" == "true" ]]; then
    show_progress "Checking for naked returns"
    
    # Simple heuristic: look for named return values and naked returns
    NAKED_RETURNS=$(rg '^\s*return\s*$' --type go -B 20 2>/dev/null | grep -E 'func.*\(.*\).*\(.*\w+.*\)' | head -5 || true)
    
    clear_progress
    
    if [[ -n "$NAKED_RETURNS" ]]; then
        add_summary "warning" "Possible naked returns in long functions"
        log_warn "Potential naked returns detected (verify manually)"
    else
        add_summary "success" "No problematic naked returns found"
    fi
fi

# 9. Check for TODO/FIXME comments
if [[ "${CLAUDE_HOOKS_GO_TODO_CHECK:-false}" == "true" ]]; then
    check_pattern 'TODO|FIXME|XXX|HACK' "TODO/FIXME comments" "" "false"
fi

# Show timing
time_end "$START_TIME"

# Print summary
print_summary

# Final result
if [[ $BLOCKING_ISSUES -gt 0 ]]; then
    log_error "Go guardrails check failed - please fix the issues above"
    exit 2
else
    if [[ $CLAUDE_HOOKS_WARNING_COUNT -gt 0 ]]; then
        log_info "Go guardrails passed with warnings"
    else
        log_success "All Go guardrails passed!"
    fi
    exit 0
fi