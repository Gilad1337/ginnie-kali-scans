#!/bin/bash
# Ginnie Cybersecurity Toolkit - Kali Linux Setup Script
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

banner() {
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║                Ginnie Cybersecurity Toolkit                  ║"
    echo "  ║              Advanced Penetration Testing Suite             ║"
    echo "  ║                  Kali Linux Setup Script                    ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_kali() {
    if ! grep -q "Kali" /etc/os-release 2>/dev/null; then
        log_warning "Not running on Kali Linux. Some tools may need manual installation."
    else
        log_success "Kali Linux detected"
    fi
}

install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Update package lists
    sudo apt update
    
    # Essential tools
    sudo apt install -y \
        curl wget git jq \
        nmap masscan \
        subfinder amass \
        testssl.sh sslyze \
        nuclei \
        sqlmap \
        gobuster dirb dirbuster \
        nikto \
        whatweb \
        wpscan \
        metasploit-framework \
        john hashcat \
        hydra medusa \
        wireshark tcpdump \
        aircrack-ng \
        setoolkit \
        recon-ng \
        theharvester \
        maltego \
        burpsuite \
        zaproxy \
        python3-pip \
        docker.io docker-compose \
        golang-go \
        nodejs npm \
        ruby-dev \
        openjdk-11-jdk
    
    # Python tools
    pip3 install --upgrade \
        semgrep \
        bandit \
        safety \
        detect-secrets \
        gitleaks \
        truffleHog \
        cloudsploit \
        scoutsuite \
        prowler \
        pacu \
        pwntools \
        impacket \
        bloodhound \
        crackmapexec \
        responder \
        mitm6 \
        requests \
        beautifulsoup4 \
        selenium \
        shodan \
        censys \
        dnsrecon \
        sublist3r \
        paramspider
    
    # Go tools
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    go install -v github.com/OWASP/Amass/v3/...@master
    go install -v github.com/tomnomnom/waybackurls@latest
    go install -v github.com/tomnomnom/gf@latest
    go install -v github.com/lc/gau@latest
    go install -v github.com/hakluke/hakrawler@latest
    
    # Install RustScan via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install rustscan
    else
        log_warning "Rust not found, skipping rustscan installation"
        log_info "You can install Rust with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
    
    # Install additional tools manually
    log_info "Installing additional security tools..."
    
    # Install yq (YAML processor)
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
    
    # Docker containers for specialized tools
    docker pull owasp/zap2docker-stable
    docker pull aquasec/trivy
    docker pull returntocorp/semgrep
    docker pull anchore/syft
    docker pull anchore/grype
    
    log_success "Dependencies installed"
}

setup_directories() {
    log_info "Setting up directory structure..."
    
    chmod +x cli/run.sh
    chmod +x .automation/preflight.sh
    chmod +x .automation/normalize.sh
    
    # Make all module runners executable
    find modules_* -name "run_module.sh" -exec chmod +x {} \;
    
    # Create reports directory
    mkdir -p reports/artifacts
    
    log_success "Directory structure set up"
}

setup_configs() {
    log_info "Setting up configuration files..."
    
    # Copy example configs if they don't exist
    if [[ ! -f AUTHORIZATION/authorization.json ]]; then
        cp AUTHORIZATION/authorization.example.json AUTHORIZATION/authorization.json
        log_warning "Created default authorization.json - PLEASE REVIEW AND CUSTOMIZE"
    fi
    
    if [[ ! -f config/scopes.yaml ]]; then
        cp config/scopes.example.yaml config/scopes.yaml
        log_warning "Created default scopes.yaml - PLEASE REVIEW AND CUSTOMIZE"
    fi
    
    if [[ ! -f cli/env ]]; then
        cp cli/env.example cli/env
        log_warning "Created default env file - PLEASE REVIEW AND CUSTOMIZE"
    fi
    
    log_success "Configuration files set up"
}

test_installation() {
    log_info "Testing installation..."
    
    # Test basic tools
    command -v nmap >/dev/null 2>&1 || { log_error "nmap not found"; exit 1; }
    command -v nuclei >/dev/null 2>&1 || { log_error "nuclei not found"; exit 1; }
    command -v httpx >/dev/null 2>&1 || { log_error "httpx not found"; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq not found"; exit 1; }
    command -v yq >/dev/null 2>&1 || { log_error "yq not found"; exit 1; }
    
    # Test preflight
    if .automation/preflight.sh; then
        log_success "Preflight check passed"
    else
        log_error "Preflight check failed"
        exit 1
    fi
    
    log_success "Installation test completed"
}

main() {
    banner
    check_kali
    install_dependencies
    setup_directories
    setup_configs
    test_installation
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   SETUP COMPLETED SUCCESSFULLY!                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "1. Review and customize ${BLUE}AUTHORIZATION/authorization.json${NC}"
    echo -e "2. Review and customize ${BLUE}config/scopes.yaml${NC}"
    echo -e "3. Run your first scan: ${BLUE}./cli/run.sh --scenario external_recon${NC}"
    echo -e "4. Check documentation: ${BLUE}docs/QUICKSTART.md${NC}"
    echo -e "\n${RED}IMPORTANT:${NC} Always ensure proper authorization before scanning!"
}

main "$@"
