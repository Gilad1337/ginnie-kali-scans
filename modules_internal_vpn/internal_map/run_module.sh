#!/bin/bash
# Internal VPN Map module runner (stub)
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
  echo "# Internal VPN Map Report" > "$dir/report.md"
}

# Main logic
check_roe
CIDR=$(yq '.environments.production.cidr[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for subnet in $CIDR; do
  echo "Running nmap for $subnet..."
  nmap -sV --version-light $subnet >> "$ARTIFACT_DIR/nmap.txt" 2>&1
done

# Service inventory (stub)
echo "Service inventory for Tailscale ranges (see nmap output)" > "$ARTIFACT_DIR/services.txt"

write_report "$ARTIFACT_DIR"

exit 0
