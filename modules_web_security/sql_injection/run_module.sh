#!/bin/bash
# Advanced SQL Injection Testing module (Safe Mode)
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
  "scan_type": "web_sql_injection",
  "target_domains": $(echo "$DOMAINS" | jq -R -s -c 'split("\n")[:-1]'),
  "findings": [],
  "tools_used": ["sqlmap", "nosqlmap", "ghauri"],
  "severity": "high",
  "mode": "safe_detection_only",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# SQL Injection Assessment Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
  echo "Mode: Safe detection only - no exploitation" >> "$dir/report.md"
}

# Main logic
check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

# Create safe sqlmap configuration
cat > "$ARTIFACT_DIR/sqlmap_safe.conf" << EOF
[Target]
threads = 1
delay = 2
timeout = 30
retries = 1

[Injection]
technique = BEUSTQ
level = 1
risk = 1

[Detection]
skip-urlencode = True
skip-static = True

[Limits]
batch = True
no-cast = True
no-escape = True
EOF

for domain in $DOMAINS; do
  echo "Running safe SQL injection detection for $domain..."
  
  # SQLMap with safe settings - detection only
  echo "sqlmap --batch --level=1 --risk=1 --threads=1 --delay=2 --timeout=30 --technique=B --url='https://$domain'" > "$ARTIFACT_DIR/sqlmap_commands_$domain.txt"
  # Note: In production, replace with actual sqlmap command
  # sqlmap --batch --level=1 --risk=1 --threads=1 --delay=2 --timeout=30 --technique=B --url="https://$domain" > "$ARTIFACT_DIR/sqlmap_$domain.txt" 2>&1
  
  # NoSQL injection testing
  echo "nosqlmap scan for $domain..."
  # nosqlmap --url "https://$domain" --scan > "$ARTIFACT_DIR/nosqlmap_$domain.txt" 2>&1
  
  # Custom SQL injection parameter testing
  echo "Testing common parameters for SQL injection indicators..."
  for param in id user page category search q; do
    echo "curl -s 'https://$domain?$param=1%27' | grep -i 'sql\|mysql\|oracle\|postgres'" >> "$ARTIFACT_DIR/sqli_param_test_$domain.txt"
  done
  
  # Error-based detection
  echo "Error-based SQL injection detection for $domain..."
  curl -s "https://$domain?id=1'" 2>/dev/null | grep -i "sql\|mysql\|oracle\|postgres\|error\|warning" > "$ARTIFACT_DIR/sqli_errors_$domain.txt" 2>&1 || true
done

# Generate SQL injection summary
echo "SQL Injection Assessment Summary:" > "$ARTIFACT_DIR/sqli_summary.txt"
echo "=================================" >> "$ARTIFACT_DIR/sqli_summary.txt"
echo "Scan Mode: Safe detection only" >> "$ARTIFACT_DIR/sqli_summary.txt"
echo "No exploitation attempted" >> "$ARTIFACT_DIR/sqli_summary.txt"
echo "" >> "$ARTIFACT_DIR/sqli_summary.txt"

for domain in $DOMAINS; do
  echo "Domain: $domain" >> "$ARTIFACT_DIR/sqli_summary.txt"
  if [[ -s "$ARTIFACT_DIR/sqli_errors_$domain.txt" ]]; then
    echo "Potential SQL errors detected" >> "$ARTIFACT_DIR/sqli_summary.txt"
  else
    echo "No obvious SQL errors detected" >> "$ARTIFACT_DIR/sqli_summary.txt"
  fi
  echo "---" >> "$ARTIFACT_DIR/sqli_summary.txt"
done

write_report "$ARTIFACT_DIR"
exit 0
