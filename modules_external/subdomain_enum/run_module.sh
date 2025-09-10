#!/bin/bash
# Advanced External Subdomain Enumeration
set -euo pipefail

# Functions for repeated logic
check_roe() {
  if [[ ! -f ../../AUTHORIZATION/authorization.json ]]; then
    echo "ROE missing. Aborting."; exit 1
  fi
  if ! grep -q '"authorized": true' ../../AUTHORIZATION/authorization.json; then
    echo "Not authorized. Aborting."; exit 1
  fi
}

write_report() {
  local dir="$1"
  cat > "$dir/findings.json" << EOF
{
  "scan_type": "subdomain_enumeration",
  "findings": [
    {
      "id": "SUBDOMAIN-001",
      "severity": "info",
      "title": "Subdomain Discovery",
      "description": "Comprehensive subdomain enumeration completed",
      "evidence": "See subdomain_list.txt for full results",
      "impact": "Expanded attack surface mapping",
      "remediation": "Review exposed subdomains and secure unnecessary services",
      "cvss": "0.0"
    }
  ]
}
EOF
  echo "# External Subdomain Enumeration Report" > "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running comprehensive subdomain enumeration for $domain..."
  
  # Passive subdomain discovery
  echo "=== Passive Discovery ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  subfinder -d "$domain" -silent >> "$ARTIFACT_DIR/subdomains_$domain.txt" 2>&1
  assetfinder --subs-only "$domain" >> "$ARTIFACT_DIR/subdomains_$domain.txt" 2>&1
  amass enum -passive -d "$domain" >> "$ARTIFACT_DIR/subdomains_$domain.txt" 2>&1
  
  # Active subdomain discovery
  echo "=== Active Discovery ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  gobuster dns -d "$domain" -w /usr/share/wordlists/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -q >> "$ARTIFACT_DIR/subdomains_$domain.txt" 2>&1
  
  # Certificate transparency logs
  echo "=== Certificate Transparency ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> "$ARTIFACT_DIR/subdomains_$domain.txt" 2>&1
  
  # DNS bruteforcing with custom wordlists
  echo "=== DNS Bruteforce ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  massdns -r /usr/share/wordlists/resolvers.txt -t A -o S -w "$ARTIFACT_DIR/massdns_$domain.txt" /usr/share/wordlists/SecLists/Discovery/DNS/fierce-hostlist.txt 2>&1
  
  # Subdomain takeover check
  echo "=== Takeover Check ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  subjack -w "$ARTIFACT_DIR/subdomains_$domain.txt" -t 100 -timeout 30 -o "$ARTIFACT_DIR/takeovers_$domain.txt" -ssl 2>&1
  
  # HTTP probing of discovered subdomains
  echo "=== HTTP Probing ===" >> "$ARTIFACT_DIR/subdomains_$domain.txt"
  httpx -l "$ARTIFACT_DIR/subdomains_$domain.txt" -o "$ARTIFACT_DIR/live_subdomains_$domain.txt" -silent 2>&1
done

write_report "$ARTIFACT_DIR"
exit 0
