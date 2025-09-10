#!/bin/bash
# ZAP Baseline module runner (stub)
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
  echo "# ZAP Baseline Report" > "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running ZAP Baseline scan for $domain..."
  zap-baseline.py -t "https://$domain" -g ../../config/zap/baseline.conf >> "$ARTIFACT_DIR/zap.txt" 2>&1
done

write_report "$ARTIFACT_DIR"

exit 0
