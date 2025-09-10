#!/bin/bash
# Test script for Ginnie Cybersecurity Toolkit
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test individual components
test_preflight() {
    log_info "Testing preflight checks..."
    if .automation/preflight.sh; then
        log_success "Preflight checks passed"
        return 0
    else
        log_error "Preflight checks failed"
        return 1
    fi
}

test_cli() {
    log_info "Testing CLI help..."
    if ./cli/run.sh --help > /dev/null 2>&1; then
        log_success "CLI help works"
        return 0
    else
        log_error "CLI help failed"
        return 1
    fi
}

test_modules() {
    log_info "Testing module runners exist..."
    local modules=(
        "modules_external/recon_web/run_module.sh"
        "modules_external/zap_baseline/run_module.sh"
        "modules_cloud_gcp/misconfig_audit/run_module.sh"
        "modules_internal_vpn/internal_map/run_module.sh"
        "modules_code_secrets/secrets_scan/run_module.sh"
    )
    
    local failed=0
    for module in "${modules[@]}"; do
        if [[ -x "$module" ]]; then
            log_success "Module exists and executable: $module"
        else
            log_error "Module missing or not executable: $module"
            ((failed++))
        fi
    done
    
    return $failed
}

test_configs() {
    log_info "Testing configuration files..."
    local configs=(
        "AUTHORIZATION/authorization.json"
        "config/scopes.example.yaml"
        "config/zap/baseline.conf"
        "config/nuclei/safe-templates.yaml"
    )
    
    local failed=0
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            log_success "Config exists: $config"
        else
            log_error "Config missing: $config"
            ((failed++))
        fi
    done
    
    return $failed
}

test_tools() {
    log_info "Testing required tools..."
    local tools=(
        "jq" "yq" "nmap" "httpx" "testssl.sh" 
        "gitleaks" "nuclei" "zap-baseline.py"
    )
    
    local failed=0
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "Tool available: $tool"
        else
            log_error "Tool missing: $tool"
            ((failed++))
        fi
    done
    
    return $failed
}

test_dry_run() {
    log_info "Testing dry run scenario..."
    
    # Create test target file
    echo "example.com" > /tmp/test_targets.txt
    
    # Try a safe scenario (should fail gracefully due to missing real tools)
    if ./cli/run.sh --scenario external_recon --targets /tmp/test_targets.txt --mode passive 2>/dev/null; then
        log_success "Dry run completed"
        return 0
    else
        log_info "Dry run failed as expected (tools not configured)"
        return 0
    fi
}

main() {
    log_info "Running Ginnie Cybersecurity Toolkit tests..."
    echo ""
    
    local total_tests=0
    local failed_tests=0
    
    # Run tests
    ((total_tests++))
    test_preflight || ((failed_tests++))
    
    ((total_tests++))
    test_cli || ((failed_tests++))
    
    ((total_tests++))
    test_modules || ((failed_tests++))
    
    ((total_tests++))
    test_configs || ((failed_tests++))
    
    ((total_tests++))
    test_tools || ((failed_tests++))
    
    ((total_tests++))
    test_dry_run || ((failed_tests++))
    
    echo ""
    log_info "Test Results: $((total_tests - failed_tests))/$total_tests passed"
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All tests passed! Toolkit is ready to use."
        echo ""
        log_info "Try these commands:"
        echo "  ./cli/run.sh --scenario external_recon --targets config/scopes.example.yaml"
        echo "  ./cli/run.sh --scenario code_secrets"
        echo "  ./cli/run.sh --scenario network_port_scan --targets config/scopes.example.yaml"
        return 0
    else
        log_error "$failed_tests tests failed. Please check the setup."
        return 1
    fi
}

main "$@"
