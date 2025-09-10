#!/bin/bash
# Advanced Preflight checks with comprehensive validation
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check ROE and authorization
check_authorization() {
    log_info "Checking Rules of Engagement..."
    
    if [[ ! -f AUTHORIZATION/authorization.json ]]; then
        log_error "ROE missing: AUTHORIZATION/authorization.json not found"
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required for JSON parsing"
        return 1
    fi
    
    # Check basic authorization
    if ! jq -e '.authorized == true' AUTHORIZATION/authorization.json > /dev/null; then
        log_error "Not authorized: authorization.json must have 'authorized': true"
        return 1
    fi
    
    log_success "Authorization checks passed"
    return 0
}

# Check tool presence
check_tools() {
    log_info "Checking required security tools..."
    
    # Define required tools
    tools=("nmap" "httpx" "nuclei" "testssl.sh" "jq" "yq" "curl" "git")
    
    missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
            log_error "Missing tool: $tool"
        else
            log_success "Found tool: $tool"
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Main preflight execution
main() {
    echo "=================================="
    echo "Ginnie Cybersecurity Toolkit"
    echo "Preflight Safety Checks"
    echo "=================================="
    
    local exit_code=0
    
    check_authorization || exit_code=1
    check_tools || exit_code=1
    
    echo "=================================="
    if [[ $exit_code -eq 0 ]]; then
        log_success "All preflight checks passed - ready to proceed"
    else
        log_error "Preflight checks failed - resolve issues before proceeding"
    fi
    echo "=================================="
    
    exit $exit_code
}

# Execute main function
main "$@"
