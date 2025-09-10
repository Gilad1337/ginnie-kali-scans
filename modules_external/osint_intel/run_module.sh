#!/bin/bash
# Advanced External OSINT Intelligence module
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
  "scan_type": "external_osint_intel",
  "target_domains": $(echo "$DOMAINS" | jq -R -s -c 'split("\n")[:-1]'),
  "findings": [],
  "tools_used": ["theHarvester", "recon-ng", "sherlock", "whatsmyname", "phoneinfoga"],
  "severity": "info",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# External OSINT Intelligence Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running theHarvester for $domain..."
  theHarvester -d "$domain" -l 500 -b all > "$ARTIFACT_DIR/harvester_$domain.txt" 2>&1
  
  echo "Running recon-ng for $domain..."
  echo "use recon/domains-hosts/hackertarget" > "$ARTIFACT_DIR/recon_commands.txt"
  echo "set SOURCE $domain" >> "$ARTIFACT_DIR/recon_commands.txt"
  echo "run" >> "$ARTIFACT_DIR/recon_commands.txt"
  recon-ng -r "$ARTIFACT_DIR/recon_commands.txt" > "$ARTIFACT_DIR/recon_$domain.txt" 2>&1
  
  echo "Running sherlock for $domain organization..."
  # Extract organization name from domain for social media searches
  ORG=$(echo "$domain" | cut -d'.' -f1)
  sherlock "$ORG" --timeout 10 > "$ARTIFACT_DIR/sherlock_$ORG.txt" 2>&1
  
  echo "Running whatsmyname for $domain..."
  whatsmyname -u "$ORG" > "$ARTIFACT_DIR/whatsmyname_$ORG.txt" 2>&1
done

# Email pattern analysis
echo "Analyzing email patterns..." > "$ARTIFACT_DIR/email_patterns.txt"
grep -h "@" "$ARTIFACT_DIR"/harvester_*.txt | sort -u >> "$ARTIFACT_DIR/email_patterns.txt" 2>/dev/null || true

# Social media intelligence
echo "Social media intelligence summary:" > "$ARTIFACT_DIR/social_intel.txt"
find "$ARTIFACT_DIR" -name "sherlock_*.txt" -exec grep -l "FOUND" {} \; >> "$ARTIFACT_DIR/social_intel.txt" 2>/dev/null || true

write_report "$ARTIFACT_DIR"
exit 0
