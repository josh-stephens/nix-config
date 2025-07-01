#!/usr/bin/env bash
# smart-lint.sh - Intelligent project-aware code quality checks for Claude Code
#
# SYNOPSIS
#   smart-lint.sh [options]
#
# DESCRIPTION
#   Automatically detects project type and runs appropriate formatting, linting,
#   and advanced quality checks. Includes basic linting for all supported
#   languages plus advanced guardrails for Go projects.
#
# OPTIONS
#   --debug       Enable debug output
#   --fast        Skip slow checks (import cycles, security scans)
#
# EXIT CODES
#   0 - Success (all checks passed or only warnings)
#   1 - General error (missing dependencies, etc.)
#   2 - Blocking errors that must be fixed
#
# CONFIGURATION
#   Project-specific overrides can be placed in .claude-hooks-config.sh
#   See inline documentation for all available options.

# Don't use set -e - we need to control exit codes carefully
set +e

# ============================================================================
# COLOR DEFINITIONS AND UTILITIES
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Debug mode
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

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# PROJECT DETECTION
# ============================================================================

detect_project_type() {
    local project_type="unknown"
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

# Get list of modified files (if available from git)
get_modified_files() {
    if [[ -d .git ]] && command_exists git; then
        # Get files modified in the last commit or currently staged/modified
        git diff --name-only HEAD 2>/dev/null || true
        git diff --cached --name-only 2>/dev/null || true
    fi
}

# Check if we should skip a file
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

# ============================================================================
# SUMMARY TRACKING
# ============================================================================

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
        echo -e "\n${BLUE}═══ Summary ═══${NC}" >&2
        for item in "${CLAUDE_HOOKS_SUMMARY[@]}"; do
            echo -e "$item" >&2
        done
        
        if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
            echo -e "\n${RED}Total errors: $CLAUDE_HOOKS_ERROR_COUNT${NC}" >&2
        fi
        if [[ $CLAUDE_HOOKS_WARNING_COUNT -gt 0 ]]; then
            echo -e "${YELLOW}Total warnings: $CLAUDE_HOOKS_WARNING_COUNT${NC}" >&2
        fi
    fi
}

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

load_config() {
    # Default configuration
    export CLAUDE_HOOKS_ENABLED="${CLAUDE_HOOKS_ENABLED:-true}"
    export CLAUDE_HOOKS_FAIL_FAST="${CLAUDE_HOOKS_FAIL_FAST:-false}"
    export CLAUDE_HOOKS_SHOW_TIMING="${CLAUDE_HOOKS_SHOW_TIMING:-false}"
    
    # Language enables
    export CLAUDE_HOOKS_GO_ENABLED="${CLAUDE_HOOKS_GO_ENABLED:-true}"
    export CLAUDE_HOOKS_PYTHON_ENABLED="${CLAUDE_HOOKS_PYTHON_ENABLED:-true}"
    export CLAUDE_HOOKS_JS_ENABLED="${CLAUDE_HOOKS_JS_ENABLED:-true}"
    export CLAUDE_HOOKS_RUST_ENABLED="${CLAUDE_HOOKS_RUST_ENABLED:-true}"
    export CLAUDE_HOOKS_NIX_ENABLED="${CLAUDE_HOOKS_NIX_ENABLED:-true}"
    
    # Go-specific settings
    export CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS="${CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS:-true}"
    export CLAUDE_HOOKS_GO_IMPORT_CYCLES="${CLAUDE_HOOKS_GO_IMPORT_CYCLES:-true}"
    export CLAUDE_HOOKS_GO_GODOC_CHECK="${CLAUDE_HOOKS_GO_GODOC_CHECK:-true}"
    export CLAUDE_HOOKS_GO_SQL_INJECTION="${CLAUDE_HOOKS_GO_SQL_INJECTION:-true}"
    export CLAUDE_HOOKS_GO_COMPLEXITY="${CLAUDE_HOOKS_GO_COMPLEXITY:-true}"
    export CLAUDE_HOOKS_GO_PRINT_STATEMENTS="${CLAUDE_HOOKS_GO_PRINT_STATEMENTS:-true}"
    export CLAUDE_HOOKS_GO_NAKED_RETURNS="${CLAUDE_HOOKS_GO_NAKED_RETURNS:-true}"
    export CLAUDE_HOOKS_GO_TODO_CHECK="${CLAUDE_HOOKS_GO_TODO_CHECK:-false}"
    export CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD="${CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD:-20}"
    
    # Project-specific overrides
    if [[ -f ".claude-hooks-config.sh" ]]; then
        source ".claude-hooks-config.sh" || {
            log_error "Failed to load .claude-hooks-config.sh"
            exit 2
        }
    fi
    
    # Quick exit if hooks are disabled
    if [[ "$CLAUDE_HOOKS_ENABLED" != "true" ]]; then
        log_info "Claude hooks are disabled"
        exit 0
    fi
}

# ============================================================================
# GO LINTING AND GUARDRAILS
# ============================================================================

# Helper function to check a specific pattern in Go files
check_go_pattern() {
    local pattern="$1"
    local description="$2"
    local exclude_pattern="${3:-}"
    local is_blocking="${4:-true}"
    
    local results=""
    if [[ -n "$exclude_pattern" ]]; then
        results=$(rg "$pattern" --type go --glob '!*_test.go' 2>/dev/null | grep -v "$exclude_pattern" | head -10 || true)
    else
        results=$(rg "$pattern" --type go --glob '!*_test.go' 2>/dev/null | head -10 || true)
    fi
    
    if [[ -n "$results" ]]; then
        if [[ "$is_blocking" == "true" ]]; then
            add_summary "error" "$description detected"
            log_error "$description detected:"
            echo "$results" | while IFS= read -r line; do
                echo "  $line" >&2
            done
            return 2
        else
            add_summary "warning" "$description detected"
            log_warn "$description detected"
            return 1
        fi
    else
        add_summary "success" "No $description found"
        return 0
    fi
}

lint_go() {
    if [[ "${CLAUDE_HOOKS_GO_ENABLED:-true}" != "true" ]]; then
        log_debug "Go linting disabled"
        return 0
    fi
    
    log_info "Running Go formatting and linting..."
    local exit_code=0
    
    # Check if Makefile exists with fmt and lint targets
    if [[ -f "Makefile" ]]; then
        local has_fmt=$(grep -E "^fmt:" Makefile 2>/dev/null || echo "")
        local has_lint=$(grep -E "^lint:" Makefile 2>/dev/null || echo "")
        
        if [[ -n "$has_fmt" && -n "$has_lint" ]]; then
            log_info "Using Makefile targets"
            
            if ! make fmt >/dev/null 2>&1; then
                add_summary "error" "Go formatting failed (make fmt)"
                exit_code=2
            else
                add_summary "success" "Go code formatted"
            fi
            
            if ! make lint 2>&1; then
                add_summary "error" "Go linting failed (make lint)"
                exit_code=2
            else
                add_summary "success" "Go linting passed"
            fi
        else
            # Fallback to direct commands
            log_info "Using direct Go tools"
            
            # Format check
            local unformatted_files=$(gofmt -l . 2>/dev/null | grep -v vendor/ || true)
            
            if [[ -n "$unformatted_files" ]]; then
                log_warn "Formatting Go files..."
                gofmt -w .
                add_summary "warning" "Go files were reformatted"
            else
                add_summary "success" "Go formatting correct"
            fi
            
            # Linting
            if command_exists golangci-lint; then
                if ! golangci-lint run --timeout=2m 2>&1; then
                    add_summary "error" "golangci-lint found issues"
                    exit_code=2
                else
                    add_summary "success" "golangci-lint passed"
                fi
            elif command_exists go; then
                if ! go vet ./... 2>&1; then
                    add_summary "error" "go vet found issues"
                    exit_code=2
                else
                    add_summary "success" "go vet passed"
                fi
            else
                log_warn "No Go linting tools available"
            fi
        fi
    else
        # No Makefile, use direct commands
        log_info "Using direct Go tools"
        
        # Format check
        local unformatted_files=$(gofmt -l . 2>/dev/null | grep -v vendor/ || true)
        
        if [[ -n "$unformatted_files" ]]; then
            log_warn "Formatting Go files..."
            gofmt -w .
            add_summary "warning" "Go files were reformatted"
        else
            add_summary "success" "Go formatting correct"
        fi
        
        # Linting
        if command_exists golangci-lint; then
            if ! golangci-lint run --timeout=2m 2>&1; then
                add_summary "error" "golangci-lint found issues"
                exit_code=2
            else
                add_summary "success" "golangci-lint passed"
            fi
        elif command_exists go; then
            if ! go vet ./... 2>&1; then
                add_summary "error" "go vet found issues"
                exit_code=2
            else
                add_summary "success" "go vet passed"
            fi
        else
            log_warn "No Go linting tools available"
        fi
    fi
    
    # Run advanced Go guardrails checks
    log_info "Running Go guardrails..."
    
    # Track blocking issues for guardrails
    local guardrails_blocking=0
    
    # 1. Check for forbidden patterns
    if [[ "${CLAUDE_HOOKS_GO_FORBIDDEN_PATTERNS:-true}" == "true" ]]; then
        # Check for time.Sleep (excluding main.go and test files)
        SLEEP_USAGE=$(rg 'time\.Sleep' --type go --glob '!*_test.go' --glob '!**/main.go' 2>/dev/null | grep -v "// nosec" | head -10 || true)
        
        if [[ -n "$SLEEP_USAGE" ]]; then
            add_summary "error" "time.Sleep usage detected (use channels for synchronization)"
            log_error "Forbidden pattern: time.Sleep found (use channels instead):"
            echo "$SLEEP_USAGE" | while IFS= read -r line; do
                echo "  $line" >&2
            done
            ((guardrails_blocking++))
        else
            add_summary "success" "No time.Sleep usage found"
        fi
        
        # Check for panic calls (excluding panic handlers)
        check_go_pattern 'panic\(' "panic() calls" "panic.*\.go|// nosec" && ((guardrails_blocking++)) || true
        
        # Check for interface{} usage
        check_go_pattern '\binterface\{\}' "interface{} usage" "// nosec|comment" && ((guardrails_blocking++)) || true
    fi
    
    # 2. Check for import cycles (slow, can be skipped in fast mode)
    if [[ "${CLAUDE_HOOKS_GO_IMPORT_CYCLES:-true}" == "true" && "$FAST_MODE" != "true" ]]; then
        IMPORT_CYCLE_RESULT=$(go list -f '{{join .Deps "\n"}}' ./... 2>&1 | xargs go list -f '{{if .Error}}{{.Error}}{{end}}' 2>&1 | grep -i 'import cycle' || echo "")
        
        if [[ -n "$IMPORT_CYCLE_RESULT" ]]; then
            add_summary "error" "Import cycle detected"
            log_error "Import cycle detected:"
            echo "$IMPORT_CYCLE_RESULT" >&2
            ((guardrails_blocking++))
        else
            add_summary "success" "No import cycles found"
        fi
    fi
    
    # 3. Check for missing godoc on exported items
    if [[ "${CLAUDE_HOOKS_GO_GODOC_CHECK:-true}" == "true" ]]; then
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
    fi
    
    # 4. Check for potential SQL injection
    if [[ "${CLAUDE_HOOKS_GO_SQL_INJECTION:-true}" == "true" ]]; then
        # First check if database/sql is even imported
        if rg -q 'database/sql' --type go 2>/dev/null; then
            check_go_pattern 'fmt\.Sprintf.*(?:SELECT|INSERT|UPDATE|DELETE|WHERE)' "SQL injection patterns" "" "true" && ((guardrails_blocking++)) || true
            
            # Also check for string concatenation with SQL
            check_go_pattern '\+.*(?:SELECT|INSERT|UPDATE|DELETE|WHERE)' "SQL string concatenation" "" "false" || true
        else
            log_debug "No database/sql usage found, skipping SQL injection checks"
        fi
    fi
    
    # 5. Check complexity (if gocognit is available)
    if [[ "${CLAUDE_HOOKS_GO_COMPLEXITY:-true}" == "true" ]] && command_exists gocognit; then
        COMPLEXITY_THRESHOLD="${CLAUDE_HOOKS_GO_COMPLEXITY_THRESHOLD:-20}"
        COMPLEX_FUNCTIONS=$(gocognit -over "$COMPLEXITY_THRESHOLD" -top 5 . 2>/dev/null | head -10 || true)
        
        if [[ -n "$COMPLEX_FUNCTIONS" ]]; then
            add_summary "warning" "Functions with high complexity found"
            log_warn "Functions exceeding complexity threshold ($COMPLEXITY_THRESHOLD):"
            echo "$COMPLEX_FUNCTIONS" >&2
        else
            add_summary "success" "All functions within complexity limits"
        fi
    fi
    
    # 6. Check for direct fmt.Print usage
    if [[ "${CLAUDE_HOOKS_GO_PRINT_STATEMENTS:-true}" == "true" ]]; then
        check_go_pattern 'fmt\.Print' "direct print statements" "cmd/.*/main\.go" "false" || true
    fi
    
    # 7. Check for naked returns in long functions
    if [[ "${CLAUDE_HOOKS_GO_NAKED_RETURNS:-true}" == "true" ]]; then
        # Simple heuristic: look for named return values and naked returns
        NAKED_RETURNS=$(rg '^\s*return\s*$' --type go -B 20 2>/dev/null | grep -E 'func.*\(.*\).*\(.*\w+.*\)' | head -5 || true)
        
        if [[ -n "$NAKED_RETURNS" ]]; then
            add_summary "warning" "Possible naked returns in long functions"
            log_warn "Potential naked returns detected (verify manually)"
        else
            add_summary "success" "No problematic naked returns found"
        fi
    fi
    
    # 8. Check for TODO/FIXME comments
    if [[ "${CLAUDE_HOOKS_GO_TODO_CHECK:-false}" == "true" ]]; then
        check_go_pattern 'TODO|FIXME|XXX|HACK' "TODO/FIXME comments" "" "false" || true
    fi
    
    # Update exit code if guardrails found blocking issues
    if [[ $guardrails_blocking -gt 0 ]]; then
        exit_code=2
    fi
    
    return $exit_code
}

# ============================================================================
# OTHER LANGUAGE LINTERS
# ============================================================================

lint_python() {
    if [[ "${CLAUDE_HOOKS_PYTHON_ENABLED:-true}" != "true" ]]; then
        log_debug "Python linting disabled"
        return 0
    fi
    
    log_info "Running Python linters..."
    
    # Black formatting
    if command_exists black; then
        if black . --check --quiet 2>/dev/null; then
            add_summary "success" "Python formatting correct"
        else
            black . --quiet 2>/dev/null
            add_summary "warning" "Python files were reformatted"
        fi
    fi
    
    # Linting
    if command_exists ruff; then
        if ! ruff check --fix . 2>&1; then
            add_summary "warning" "Ruff found and fixed issues"
        else
            add_summary "success" "Ruff check passed"
        fi
    elif command_exists flake8; then
        if flake8 . 2>&1; then
            add_summary "success" "Flake8 check passed"
        else
            add_summary "warning" "Flake8 found issues"
        fi
    fi
    
    return 0
}

lint_javascript() {
    if [[ "${CLAUDE_HOOKS_JS_ENABLED:-true}" != "true" ]]; then
        log_debug "JavaScript linting disabled"
        return 0
    fi
    
    log_info "Running JavaScript/TypeScript linters..."
    
    # Check for ESLint
    if [[ -f "package.json" ]] && grep -q "eslint" package.json 2>/dev/null; then
        if command_exists npm; then
            if npm run lint --if-present 2>&1; then
                add_summary "success" "ESLint check passed"
            else
                add_summary "warning" "ESLint found issues"
            fi
        fi
    fi
    
    # Prettier
    if [[ -f ".prettierrc" ]] || [[ -f "prettier.config.js" ]] || [[ -f ".prettierrc.json" ]]; then
        if command_exists prettier; then
            if prettier --check . 2>/dev/null; then
                add_summary "success" "Prettier formatting correct"
            else
                prettier --write . 2>/dev/null
                add_summary "warning" "Files were reformatted with Prettier"
            fi
        elif command_exists npx; then
            if npx prettier --check . 2>/dev/null; then
                add_summary "success" "Prettier formatting correct"
            else
                npx prettier --write . 2>/dev/null
                add_summary "warning" "Files were reformatted with Prettier"
            fi
        fi
    fi
    
    return 0
}

lint_rust() {
    if [[ "${CLAUDE_HOOKS_RUST_ENABLED:-true}" != "true" ]]; then
        log_debug "Rust linting disabled"
        return 0
    fi
    
    log_info "Running Rust linters..."
    
    if command_exists cargo; then
        if cargo fmt -- --check 2>/dev/null; then
            add_summary "success" "Rust formatting correct"
        else
            cargo fmt 2>/dev/null
            add_summary "warning" "Rust files were reformatted"
        fi
        
        if cargo clippy --quiet -- -D warnings 2>&1; then
            add_summary "success" "Clippy check passed"
        else
            add_summary "warning" "Clippy found issues"
        fi
    else
        log_warn "Cargo not found, skipping Rust checks"
    fi
    
    return 0
}

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
        if echo "$nix_files" | xargs nixpkgs-fmt --check 2>/dev/null; then
            add_summary "success" "Nix formatting correct"
        else
            echo "$nix_files" | xargs nixpkgs-fmt 2>/dev/null
            add_summary "warning" "Nix files were reformatted"
        fi
    elif command_exists alejandra; then
        if echo "$nix_files" | xargs alejandra --check 2>/dev/null; then
            add_summary "success" "Nix formatting correct"
        else
            echo "$nix_files" | xargs alejandra --quiet 2>/dev/null
            add_summary "warning" "Nix files were reformatted"
        fi
    fi
    
    # Static analysis with statix
    if command_exists statix; then
        if statix check 2>&1; then
            add_summary "success" "Statix check passed"
        else
            add_summary "warning" "Statix found issues"
        fi
    fi
    
    return 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Parse command line options
FAST_MODE=false
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
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

# Print header
echo "" >&2
echo "🔍 Smart Lint - Language-specific code quality checks" >&2
echo "────────────────────────────────────────────────────" >&2

# Load configuration
load_config

# Start timing
START_TIME=$(time_start)

# Detect project type
PROJECT_TYPE=$(detect_project_type)
log_info "Project type: $PROJECT_TYPE"

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
exit_code=$?
log_info "smart-lint.sh completed with exit code: $exit_code"
exit $exit_code