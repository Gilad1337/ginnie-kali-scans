#!/bin/bash
# Advanced Purple Team Exercise Coordination module
set -euo pipefail

# Functions for repeated logic
check_roe() {
  if [[ ! -f ../../AUTHORIZATION/authorization.json ]]; then
    echo "ROE missing. Aborting."; exit 1
  fi
  if ! grep -q '"authorized": true' ../../AUTHORIZATION/authorization.json; then
    echo "Not authorized. Aborting."; exit 1
  fi
  
  # Extra check for purple team scenarios
  if ! grep -q '"purple_team_authorized": true' ../../AUTHORIZATION/authorization.json; then
    echo "Purple team activities not authorized. Aborting."; exit 1
  fi
}

write_report() {
  local dir="$1"
  cat > "$dir/findings.json" << EOF
{
  "scan_type": "purple_team_exercise",
  "target_organization": "$(jq -r '.owner' ../../AUTHORIZATION/authorization.json)",
  "findings": [],
  "tools_used": ["caldera", "atomic-red-team", "detection-lab", "sigma"],
  "severity": "collaborative",
  "mode": "defensive_improvement",
  "frameworks": ["MITRE ATT&CK", "NIST", "Cyber Kill Chain"],
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# Purple Team Exercise Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
  echo "Mode: Collaborative red/blue team exercise" >> "$dir/report.md"
}

# Main logic
check_roe

ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

echo "Purple Team Exercise Coordination"
echo "================================="

# Generate MITRE ATT&CK test scenarios
cat > "$ARTIFACT_DIR/attack_scenarios.txt" << EOF
MITRE ATT&CK Purple Team Test Scenarios:
========================================

Scenario 1: Initial Access & Execution
- Technique: T1566.001 (Spearphishing Attachment)
- Technique: T1059.001 (PowerShell)
- Detection Goal: Email security and endpoint monitoring

Scenario 2: Persistence & Privilege Escalation  
- Technique: T1547.001 (Registry Run Keys)
- Technique: T1055 (Process Injection)
- Detection Goal: System monitoring and behavioral analysis

Scenario 3: Defense Evasion & Discovery
- Technique: T1070.004 (File Deletion)
- Technique: T1083 (File and Directory Discovery)
- Detection Goal: File integrity monitoring

Scenario 4: Lateral Movement & Collection
- Technique: T1021.001 (Remote Desktop Protocol)
- Technique: T1005 (Data from Local System)
- Detection Goal: Network monitoring and data loss prevention

Scenario 5: Exfiltration & Impact
- Technique: T1041 (Exfiltration Over C2 Channel)
- Technique: T1486 (Data Encrypted for Impact)
- Detection Goal: Network traffic analysis and backup validation
EOF

# Detection engineering playbook
cat > "$ARTIFACT_DIR/detection_playbook.txt" << EOF
Purple Team Detection Engineering Playbook:
===========================================

Pre-Exercise Phase:
1. Map current detection capabilities
2. Identify coverage gaps
3. Set exercise objectives
4. Prepare testing environment

Exercise Execution:
1. Red team executes attack techniques
2. Blue team monitors and responds
3. Real-time collaboration and feedback
4. Document detection successes/failures

Post-Exercise Analysis:
1. Review detection coverage
2. Analyze false positives/negatives
3. Tune detection rules
4. Update response procedures

Key Metrics:
- Mean Time to Detection (MTTD)
- Mean Time to Response (MTTR)
- Detection coverage percentage
- False positive rate
EOF

# Atomic Red Team test catalog
cat > "$ARTIFACT_DIR/atomic_tests.txt" << EOF
Atomic Red Team Test Catalog:
=============================

T1059.001 - PowerShell Execution:
Command: powershell.exe -Command "Write-Host 'Purple Team Test'"
Detection: Process monitoring, command line logging

T1003.001 - LSASS Memory Dump:
Command: rundll32.exe C:\windows\System32\comsvcs.dll, MiniDump [PID] lsass.dmp full
Detection: Process access monitoring, file creation alerts

T1055.002 - Portable Executable Injection:
Test: Inject test payload into legitimate process
Detection: Process hollowing detection, memory scanning

T1070.004 - File Deletion:
Command: del /f /q C:\temp\testfile.txt
Detection: File system monitoring, audit logs

T1083 - File and Directory Discovery:
Command: dir C:\ /s /b
Detection: Process monitoring, unusual file access patterns
EOF

# Detection rule improvements
cat > "$ARTIFACT_DIR/detection_improvements.txt" << EOF
Detection Rule Improvement Recommendations:
===========================================

SIEM Rule Enhancements:
1. PowerShell execution with encoded commands
2. Suspicious process creation chains
3. Unusual network connections
4. File system modifications in sensitive directories
5. Registry modifications for persistence

Endpoint Detection:
1. Process injection techniques
2. Memory dump activities
3. Credential access attempts
4. Lateral movement indicators
5. Data staging activities

Network Detection:
1. DNS tunneling detection
2. Command and control communications
3. Data exfiltration patterns
4. Suspicious protocol usage
5. Encrypted traffic analysis

Behavioral Analytics:
1. User behavior anomalies
2. System behavior deviations
3. Time-based analysis
4. Peer group comparisons
5. Risk scoring models
EOF

# Exercise coordination timeline
cat > "$ARTIFACT_DIR/exercise_timeline.txt" << EOF
Purple Team Exercise Timeline:
==============================

Week 1: Planning and Preparation
- Define scope and objectives
- Set up testing environment
- Brief red and blue teams
- Establish communication channels

Week 2: Baseline Assessment
- Map current detection capabilities
- Document existing security controls
- Establish baseline metrics
- Test communication procedures

Week 3: Exercise Execution
Day 1: Initial access scenarios
Day 2: Persistence and escalation
Day 3: Lateral movement and discovery
Day 4: Collection and exfiltration
Day 5: Impact and remediation

Week 4: Analysis and Improvement
- Analyze detection performance
- Review response procedures
- Tune security controls
- Document lessons learned
- Plan follow-up exercises
EOF

# Generate CALDERA operation plan
cat > "$ARTIFACT_DIR/caldera_operations.txt" << EOF
CALDERA Purple Team Operations:
===============================

Operation 1: Basic Discovery
- Fact: host.os.name
- Abilities: System info, network config, user enumeration
- Blue team objective: Detect reconnaissance

Operation 2: Credential Access
- Fact: credential access techniques
- Abilities: Password dumping, hash extraction
- Blue team objective: Detect credential theft

Operation 3: Persistence Mechanisms
- Fact: persistence techniques
- Abilities: Registry modifications, scheduled tasks
- Blue team objective: Detect persistence establishment

Operation 4: Defense Evasion
- Fact: evasion techniques  
- Abilities: Process hiding, log evasion
- Blue team objective: Detect evasion attempts

Operation 5: Lateral Movement
- Fact: network topology
- Abilities: Remote execution, service exploitation
- Blue team objective: Detect lateral movement
EOF

echo "Purple team exercise planning completed"
echo "Collaborative red/blue team scenarios generated"
echo "Review exercise plans and coordinate team activities"

write_report "$ARTIFACT_DIR"
exit 0
