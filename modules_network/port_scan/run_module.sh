#!/bin/bash
# Advanced Network Port Scanning and Service Enumeration
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
  "scan_type": "network_port_scan",
  "findings": [
    {
      "id": "NET-001",
      "severity": "medium",
      "title": "Open Ports Detected",
      "description": "Network services and open ports identified",
      "evidence": "See nmap_results.txt for detailed port information",
      "impact": "Potential attack vectors and service exposure",
      "remediation": "Close unnecessary ports, implement port-based access controls",
      "cvss": "5.3"
    }
  ]
}
EOF
  echo "# Network Port Scan Report" > "$dir/report.md"
}

check_roe
TARGETS=$(yq '.environments.production.cidr[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for target in $TARGETS; do
  echo "Running comprehensive port scan for $target..."
  
  # TCP SYN scan - fast and stealthy
  echo "=== TCP SYN Scan ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap -sS -T4 -p- --open --reason "$target" >> "$ARTIFACT_DIR/tcp_syn_$target.txt" 2>&1
  
  # TCP Connect scan for reliable results
  echo "=== TCP Connect Scan ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap -sT -T4 -p 1-65535 --open "$target" >> "$ARTIFACT_DIR/tcp_connect_$target.txt" 2>&1
  
  # UDP scan for critical services
  echo "=== UDP Scan ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap -sU -T4 -p 53,67,68,69,123,135,137,138,139,161,162,445,500,514,1434 "$target" >> "$ARTIFACT_DIR/udp_scan_$target.txt" 2>&1
  
  # Service version detection
  echo "=== Service Detection ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap -sV -sC --version-intensity 9 "$target" >> "$ARTIFACT_DIR/service_detection_$target.txt" 2>&1
  
  # OS fingerprinting
  echo "=== OS Detection ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap -O --osscan-guess "$target" >> "$ARTIFACT_DIR/os_detection_$target.txt" 2>&1
  
  # NSE scripts for vulnerability detection
  echo "=== Vulnerability Scripts ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap --script vuln "$target" >> "$ARTIFACT_DIR/vuln_scripts_$target.txt" 2>&1
  
  # Advanced service enumeration
  echo "=== Advanced Enumeration ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  nmap --script "default,discovery,safe" "$target" >> "$ARTIFACT_DIR/enum_scripts_$target.txt" 2>&1
  
  # Masscan for high-speed scanning
  echo "=== Masscan High-Speed ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  masscan -p1-65535 "$target" --rate=1000 >> "$ARTIFACT_DIR/masscan_$target.txt" 2>&1
  
  # Specific service enumeration
  # SMB enumeration
  echo "=== SMB Enumeration ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  enum4linux -a "$target" >> "$ARTIFACT_DIR/smb_enum_$target.txt" 2>&1
  smbclient -L "$target" -N >> "$ARTIFACT_DIR/smb_shares_$target.txt" 2>&1
  
  # SSH enumeration
  echo "=== SSH Enumeration ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  ssh-audit "$target" >> "$ARTIFACT_DIR/ssh_audit_$target.txt" 2>&1
  
  # Web service enumeration
  echo "=== Web Service Enum ===" >> "$ARTIFACT_DIR/portscan_$target.txt"
  whatweb "$target" >> "$ARTIFACT_DIR/whatweb_$target.txt" 2>&1
  
done

write_report "$ARTIFACT_DIR"
exit 0
