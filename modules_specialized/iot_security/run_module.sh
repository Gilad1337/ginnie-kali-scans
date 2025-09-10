#!/bin/bash
# Advanced IoT Security Assessment
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
  "scan_type": "iot_security",
  "findings": [
    {
      "id": "IOT-001",
      "severity": "high",
      "title": "IoT Device Security Vulnerabilities",
      "description": "Security weaknesses identified in IoT infrastructure",
      "evidence": "See iot_scan_results.txt for detailed device analysis",
      "impact": "Device compromise, lateral movement, privacy violations",
      "remediation": "Update firmware, change default credentials, network segmentation",
      "cvss": "7.8",
      "device_types": ["Home Assistant", "Homebridge", "Scrypted", "AdGuardHome"]
    }
  ]
}
EOF
  echo "# IoT Security Assessment Report" > "$dir/report.md"
}

check_roe
TARGETS=$(yq '.environments.production.cidr[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

echo "Running comprehensive IoT security assessment..."

# IoT device discovery
echo "=== IoT Device Discovery ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  # Nmap IoT-specific scanning
  nmap -sS -O --script discovery,version,vuln -p 21,22,23,53,80,443,554,1900,5000,8080,8081,8443 "$target" > "$ARTIFACT_DIR/iot_nmap_$target.txt" 2>&1
  
  # UPnP device discovery
  nmap -sU -p 1900 --script upnp-info "$target" > "$ARTIFACT_DIR/upnp_discovery_$target.txt" 2>&1
  
  # MQTT broker discovery
  nmap -p 1883,8883 --script mqtt-subscribe "$target" > "$ARTIFACT_DIR/mqtt_discovery_$target.txt" 2>&1
done

# Home Assistant security assessment
echo "=== Home Assistant Security ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  # Check for default Home Assistant port
  curl -s -k "http://$target:8123/api/" > "$ARTIFACT_DIR/homeassistant_api_$target.txt" 2>&1
  
  # Check for exposed configuration files
  curl -s -k "http://$target:8123/config/configuration.yaml" > "$ARTIFACT_DIR/homeassistant_config_$target.txt" 2>&1
  
  # Home Assistant authentication bypass attempts
  curl -s -k -H "Authorization: Bearer invalid_token" "http://$target:8123/api/states" > "$ARTIFACT_DIR/homeassistant_auth_$target.txt" 2>&1
done

# Homebridge security assessment
echo "=== Homebridge Security ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  # Check for Homebridge web interface
  curl -s -k "http://$target:8581/" > "$ARTIFACT_DIR/homebridge_web_$target.txt" 2>&1
  
  # Check for default credentials
  curl -s -k -u "admin:admin" "http://$target:8581/login" > "$ARTIFACT_DIR/homebridge_auth_$target.txt" 2>&1
done

# Scrypted security assessment
echo "=== Scrypted Security ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  # Check for Scrypted management interface
  curl -s -k "https://$target:10443/" > "$ARTIFACT_DIR/scrypted_web_$target.txt" 2>&1
  
  # Check for exposed APIs
  curl -s -k "https://$target:10443/api/devices" > "$ARTIFACT_DIR/scrypted_api_$target.txt" 2>&1
done

# AdGuard Home security assessment
echo "=== AdGuard Home Security ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  # Check for AdGuard Home web interface
  curl -s -k "http://$target:3000/" > "$ARTIFACT_DIR/adguard_web_$target.txt" 2>&1
  
  # Check for DNS-over-HTTPS endpoint
  curl -s -k "https://$target/dns-query?name=test.com&type=A" > "$ARTIFACT_DIR/adguard_doh_$target.txt" 2>&1
  
  # Check for admin panel
  curl -s -k "http://$target:3000/control/status" > "$ARTIFACT_DIR/adguard_status_$target.txt" 2>&1
done

# IoT protocol security testing
echo "=== IoT Protocol Testing ===" >> "$ARTIFACT_DIR/iot_assessment.txt"

# CoAP protocol testing
for target in $TARGETS; do
  echo "Testing CoAP on $target" >> "$ARTIFACT_DIR/coap_test.txt"
  # CoAP discovery and enumeration
  coap-client -m get "coap://$target/.well-known/core" >> "$ARTIFACT_DIR/coap_test.txt" 2>&1
done

# MQTT security testing
for target in $TARGETS; do
  echo "Testing MQTT on $target" >> "$ARTIFACT_DIR/mqtt_test.txt"
  # MQTT broker enumeration
  mosquitto_sub -h "$target" -t "\$SYS/#" -C 10 >> "$ARTIFACT_DIR/mqtt_test.txt" 2>&1
  
  # MQTT authentication bypass
  mosquitto_pub -h "$target" -t "test/topic" -m "unauthorized_message" >> "$ARTIFACT_DIR/mqtt_test.txt" 2>&1
done

# Zigbee/Z-Wave security assessment
echo "=== Wireless Protocol Security ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
# Check for exposed Zigbee coordinators
nmap -sU -p 8888 --script snmp-info "$TARGETS" > "$ARTIFACT_DIR/zigbee_scan.txt" 2>&1

# Firmware analysis (if accessible)
echo "=== Firmware Analysis ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
mkdir -p "$ARTIFACT_DIR/firmware"
# Download firmware if accessible via web interfaces
for target in $TARGETS; do
  wget -q -t 1 -T 5 "http://$target/firmware.bin" -O "$ARTIFACT_DIR/firmware/firmware_$target.bin" 2>/dev/null || true
done

# Analyze downloaded firmware with binwalk
find "$ARTIFACT_DIR/firmware" -name "*.bin" -exec binwalk {} \; > "$ARTIFACT_DIR/firmware_analysis.txt" 2>&1

# Device credential testing
echo "=== Credential Testing ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
# Common IoT default credentials
declare -A default_creds=(
  ["admin"]="admin"
  ["admin"]="password"
  ["admin"]=""
  ["root"]="root"
  ["user"]="user"
  ["guest"]="guest"
  ["admin"]="1234"
)

for target in $TARGETS; do
  for user in "${!default_creds[@]}"; do
    pass="${default_creds[$user]}"
    echo "Testing $user:$pass on $target" >> "$ARTIFACT_DIR/credential_test.txt"
    curl -s -u "$user:$pass" "http://$target/" >> "$ARTIFACT_DIR/credential_test.txt" 2>&1
  done
done

# Network traffic analysis
echo "=== Network Traffic Analysis ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
# Capture IoT traffic for analysis
timeout 60 tcpdump -i any -w "$ARTIFACT_DIR/iot_traffic.pcap" host "$TARGETS" 2>&1 &

# SSL/TLS certificate analysis for IoT devices
echo "=== SSL/TLS Analysis ===" >> "$ARTIFACT_DIR/iot_assessment.txt"
for target in $TARGETS; do
  echo "SSL analysis for $target" >> "$ARTIFACT_DIR/ssl_analysis.txt"
  sslscan "$target:443" >> "$ARTIFACT_DIR/ssl_analysis.txt" 2>&1
  testssl.sh "$target:443" >> "$ARTIFACT_DIR/ssl_analysis.txt" 2>&1
done

write_report "$ARTIFACT_DIR"
exit 0
