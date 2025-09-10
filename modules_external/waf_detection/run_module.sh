#!/bin/bash
# Advanced WAF Detection and Analysis module
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
  "scan_type": "external_waf_detection",
  "target_domains": $(echo "$DOMAINS" | jq -R -s -c 'split("\n")[:-1]'),
  "findings": [],
  "tools_used": ["wafw00f", "whatwaf", "nmap"],
  "severity": "info",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# WAF Detection and Analysis Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running wafw00f for $domain..."
  wafw00f "https://$domain" > "$ARTIFACT_DIR/wafw00f_$domain.txt" 2>&1
  
  echo "Running whatwaf for $domain..."
  whatwaf --url "https://$domain" --verbose > "$ARTIFACT_DIR/whatwaf_$domain.txt" 2>&1
  
  echo "Running nmap WAF detection scripts for $domain..."
  nmap -p 80,443 --script http-waf-detect,http-waf-fingerprint "$domain" > "$ARTIFACT_DIR/nmap_waf_$domain.txt" 2>&1
  
  echo "Testing common WAF bypass techniques for $domain..."
  # Safe WAF bypass testing - headers only
  curl -H "X-Originating-IP: 127.0.0.1" -H "X-Forwarded-For: 127.0.0.1" -H "X-Remote-IP: 127.0.0.1" \
       -H "X-Remote-Addr: 127.0.0.1" -H "X-Client-IP: 127.0.0.1" \
       -I "https://$domain" > "$ARTIFACT_DIR/waf_bypass_headers_$domain.txt" 2>&1
done

# WAF summary analysis
echo "WAF Detection Summary:" > "$ARTIFACT_DIR/waf_summary.txt"
echo "=====================" >> "$ARTIFACT_DIR/waf_summary.txt"
for domain in $DOMAINS; do
  echo "Domain: $domain" >> "$ARTIFACT_DIR/waf_summary.txt"
  if grep -q "is behind" "$ARTIFACT_DIR/wafw00f_$domain.txt" 2>/dev/null; then
    grep "is behind" "$ARTIFACT_DIR/wafw00f_$domain.txt" >> "$ARTIFACT_DIR/waf_summary.txt" 2>/dev/null
  else
    echo "No WAF detected by wafw00f" >> "$ARTIFACT_DIR/waf_summary.txt"
  fi
  echo "---" >> "$ARTIFACT_DIR/waf_summary.txt"
done

write_report "$ARTIFACT_DIR"
exit 0
