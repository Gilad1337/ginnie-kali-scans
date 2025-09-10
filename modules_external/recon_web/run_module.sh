#!/bin/bash
# Recon Web module runner (stub)
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
  echo "{}" > "$dir/findings.json"
  echo "# Recon Web Report" > "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
RATE_LIMIT=50
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running passive DNS for $domain..."
  passivedns $domain >> "$ARTIFACT_DIR/passive_dns.txt" 2>&1
  echo "Running httpx probing for $domain..."
  httpx -u $domain >> "$ARTIFACT_DIR/httpx.txt" 2>&1
  echo "Running nmap for $domain..."
  nmap -sV --version-light $domain --rate $RATE_LIMIT >> "$ARTIFACT_DIR/nmap.txt" 2>&1
  echo "Running testssl.sh for $domain..."
  testssl.sh $domain >> "$ARTIFACT_DIR/tls.txt" 2>&1
done

write_report "$ARTIFACT_DIR"

exit 0
