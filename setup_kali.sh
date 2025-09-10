#!/bin/bash
# Ginnie Cybersecurity Toolkit - Kali Linux Setup Script
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

check_kali() {
    if [[ ! -f /etc/debian_version ]] || ! grep -q "kali" /etc/os-release 2>/dev/null; then
        log_warning "This script is optimized for Kali Linux"
    else
        log_success "Kali Linux detected"
    fi
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update package list
    sudo apt update
    
    # Core tools (most should be in Kali by default)
    PACKAGES=(
        # Basic utilities
        jq yq curl wget git
        
        # Network scanning
        nmap masscan rustscan
        
        # Web tools
        httpx subfinder assetfinder amass
        gobuster dirb dirbuster
        
        # SSL/TLS
        testssl.sh sslyze
        
        # Vulnerability scanners
        nuclei nikto
        
        # OWASP ZAP
        zaproxy
        
        # Code analysis
        gitleaks detect-secrets semgrep
        
        # Container security
        trivy docker-bench-security
        
        # Cloud tools
        awscli azure-cli google-cloud-sdk
        
        # Additional pentest tools
        sqlmap wfuzz ffuf
        burpsuite hydra john hashcat
        metasploit-framework
        
        # Python tools
        python3-pip python3-venv
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Installing $package..."
            sudo apt install -y "$package" || log_warning "Failed to install $package"
        else
            log_success "$package already installed"
        fi
    done
}

install_go_tools() {
    log_info "Installing Go-based security tools..."
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        log_info "Installing Go..."
        sudo apt install -y golang-go
    fi
    
    # Go tools
    GO_TOOLS=(
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/tomnomnom/httprobe@latest"
        "github.com/tomnomnom/waybackurls@latest"
    )
    
    for tool in "${GO_TOOLS[@]}"; do
        log_info "Installing $(basename $tool)..."
        go install "$tool" || log_warning "Failed to install $tool"
    done
    
    # Add Go bin to PATH if not already
    if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
        export PATH=$PATH:$HOME/go/bin
    fi
}

install_python_tools() {
    log_info "Installing Python security tools..."
    
    # Create virtual environment for security tools
    if [[ ! -d ~/.venv/security ]]; then
        python3 -m venv ~/.venv/security
    fi
    
    source ~/.venv/security/bin/activate
    
    # Python tools
    PYTHON_TOOLS=(
        "scoutsuite"
        "prowler"
        "syft"
        "grype"
        "bandit"
        "safety"
        "checkov"
        "terrascan"
    )
    
    for tool in "${PYTHON_TOOLS[@]}"; do
        log_info "Installing $tool..."
        pip install "$tool" || log_warning "Failed to install $tool"
    done
    
    deactivate
}

setup_directories() {
    log_info "Setting up directory structure..."
    
    # Make scripts executable
    find . -name "*.sh" -exec chmod +x {} \;
    
    # Create necessary directories
    mkdir -p reports/artifacts
    mkdir -p config/wordlists
    mkdir -p config/payloads
    
    log_success "Directory structure ready"
}

create_authorization() {
    log_info "Creating authorization file..."
    
    if [[ ! -f AUTHORIZATION/authorization.json ]]; then
        cat > AUTHORIZATION/authorization.json << 'EOF'
{
  "authorized": true,
  "owner": "Ginnie Smart Homes",
  "assessment_type": "internal_authorized",
  "in_scope": {
    "domains": [
      "ginnie.co.il",
      "smartshop.co.il",
      "*.ginnie.co.il",
      "*.smartshop.co.il"
    ],
    "cidr": [
      "100.64.0.0/10",
      "192.168.1.0/24"
    ],
    "gcp_projects": [
      "ginnie-prod",
      "ginnie-staging"
    ],
    "internal_services": [
      "home-assistant",
      "homebridge", 
      "scrypted",
      "adguardhome"
    ]
  },
  "out_of_scope": {
    "domains": [
      "customer-*.ginnie.co.il"
    ],
    "cidr": [
      "169.254.0.0/16"
    ],
    "notes": "Customer networks are out of scope unless explicitly authorized"
  },
  "windows": [
    {
      "start": "2025-09-10T00:00:00+03:00",
      "end": "2025-12-31T23:59:59+03:00",
      "description": "Development and testing window"
    }
  ],
  "contacts": [
    "secops@ginnie.co.il"
  ],
  "restrictions": {
    "no_dos": true,
    "no_data_exfiltration": true,
    "rate_limited": true,
    "passive_preferred": true
  }
}
EOF
        log_success "Authorization file created"
    else
        log_success "Authorization file already exists"
    fi
}

download_wordlists() {
    log_info "Downloading wordlists..."
    
    # SecLists
    if [[ ! -d config/wordlists/SecLists ]]; then
        git clone https://github.com/danielmiessler/SecLists.git config/wordlists/SecLists
    fi
    
    # Common wordlists
    WORDLISTS=(
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
        "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt"
    )
    
    for wordlist in "${WORDLISTS[@]}"; do
        filename=$(basename "$wordlist")
        if [[ ! -f config/wordlists/$filename ]]; then
            wget -q "$wordlist" -O config/wordlists/"$filename"
        fi
    done
    
    log_success "Wordlists ready"
}

main() {
    log_info "Setting up Ginnie Cybersecurity Toolkit for Kali Linux..."
    
    check_kali
    install_dependencies
    install_go_tools
    install_python_tools
    setup_directories
    create_authorization
    download_wordlists
    
    log_success "Setup complete!"
    echo ""
    log_info "To get started:"
    echo "  1. Review AUTHORIZATION/authorization.json"
    echo "  2. Run: ./cli/run.sh --help"
    echo "  3. Try: ./cli/run.sh --scenario external_recon --targets config/scopes.example.yaml"
    echo ""
    log_info "For testing: ./test_toolkit.sh"
}

main "$@"
