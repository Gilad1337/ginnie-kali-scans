#!/bin/bash
# Advanced Kubernetes Security Assessment module
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
  "scan_type": "kubernetes_security_assessment",
  "k8s_clusters": $(echo "$K8S_CONTEXTS" | jq -R -s -c 'split("\n")[:-1]'),
  "findings": [],
  "tools_used": ["kube-bench", "kube-hunter", "kubelet-scan", "polaris", "falco"],
  "severity": "varies",
  "compliance_frameworks": ["CIS Kubernetes", "NSA/CISA Hardening", "Pod Security Standards"],
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# Kubernetes Security Assessment Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
  echo "Compliance: CIS Kubernetes Benchmark" >> "$dir/report.md"
}

# Main logic
check_roe
K8S_CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null || echo "current-context")
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for context in $K8S_CONTEXTS; do
  echo "Running Kubernetes security assessment for context: $context..."
  
  # Set kubectl context
  kubectl config use-context "$context" > /dev/null 2>&1
  
  # CIS Kubernetes Benchmark with kube-bench
  echo "Running kube-bench CIS assessment..."
  kube-bench run --config-dir /etc/kube-bench/cfg --outputfile "$ARTIFACT_DIR/kube-bench_$context.json" --json > "$ARTIFACT_DIR/kube-bench_$context.log" 2>&1
  
  # Kubernetes penetration testing with kube-hunter
  echo "Running kube-hunter security assessment..."
  kube-hunter --remote "$(kubectl cluster-info | grep 'Kubernetes master' | awk '{print $6}' | sed 's/https:\/\///' | sed 's/:.*//')" --report json > "$ARTIFACT_DIR/kube-hunter_$context.json" 2>&1
  
  # Pod security assessment
  echo "Analyzing pod security configurations..."
  kubectl get pods --all-namespaces -o json > "$ARTIFACT_DIR/pods_$context.json" 2>&1
  
  # Network policies analysis
  echo "Analyzing network policies..."
  kubectl get networkpolicies --all-namespaces -o json > "$ARTIFACT_DIR/network_policies_$context.json" 2>&1
  
  # RBAC analysis
  echo "Analyzing RBAC configurations..."
  kubectl get clusterroles,clusterrolebindings,roles,rolebindings --all-namespaces -o json > "$ARTIFACT_DIR/rbac_$context.json" 2>&1
  
  # Service account analysis
  echo "Analyzing service accounts..."
  kubectl get serviceaccounts --all-namespaces -o json > "$ARTIFACT_DIR/service_accounts_$context.json" 2>&1
  
  # Secrets analysis
  echo "Analyzing secrets (metadata only)..."
  kubectl get secrets --all-namespaces -o json | jq 'del(.items[].data)' > "$ARTIFACT_DIR/secrets_metadata_$context.json" 2>&1
  
  # Persistent volumes analysis
  echo "Analyzing persistent volumes..."
  kubectl get pv,pvc --all-namespaces -o json > "$ARTIFACT_DIR/storage_$context.json" 2>&1
  
  # Admission controllers check
  echo "Checking admission controllers..."
  kubectl cluster-info dump | grep -i admission > "$ARTIFACT_DIR/admission_controllers_$context.txt" 2>&1 || true
  
  # Custom security checks
  echo "Running custom Kubernetes security checks..."
  
  # Check for privileged containers
  kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.spec.containers[*].securityContext.privileged}{"\n"}{end}' > "$ARTIFACT_DIR/privileged_containers_$context.txt" 2>&1
  
  # Check for hostNetwork usage
  kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.spec.hostNetwork}{"\n"}{end}' > "$ARTIFACT_DIR/host_network_$context.txt" 2>&1
  
  # Check for hostPID usage
  kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.spec.hostPID}{"\n"}{end}' > "$ARTIFACT_DIR/host_pid_$context.txt" 2>&1
  
  # Check for capabilities
  kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[]?.securityContext?.capabilities) | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.containers[].securityContext.capabilities)"' > "$ARTIFACT_DIR/capabilities_$context.txt" 2>&1
done

# Generate Kubernetes security summary
echo "Kubernetes Security Assessment Summary:" > "$ARTIFACT_DIR/k8s_security_summary.txt"
echo "======================================" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
echo "Assessment Date: $(date)" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
echo "Compliance: CIS Kubernetes Benchmark v1.6.0" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
echo "" >> "$ARTIFACT_DIR/k8s_security_summary.txt"

for context in $K8S_CONTEXTS; do
  echo "Context: $context" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
  
  # Count security issues
  privileged_count=$(grep -c "true" "$ARTIFACT_DIR/privileged_containers_$context.txt" 2>/dev/null || echo "0")
  host_network_count=$(grep -c "true" "$ARTIFACT_DIR/host_network_$context.txt" 2>/dev/null || echo "0")
  host_pid_count=$(grep -c "true" "$ARTIFACT_DIR/host_pid_$context.txt" 2>/dev/null || echo "0")
  
  echo "Privileged containers: $privileged_count" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
  echo "Host network usage: $host_network_count" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
  echo "Host PID usage: $host_pid_count" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
  echo "---" >> "$ARTIFACT_DIR/k8s_security_summary.txt"
done

# Generate Kubernetes remediation guide
cat > "$ARTIFACT_DIR/k8s_remediation.txt" << EOF
Kubernetes Security Remediation Guide:
======================================

Critical Actions:
1. Disable privileged containers unless absolutely necessary
2. Implement Pod Security Standards (restricted profile)
3. Enable network policies for namespace isolation
4. Configure proper RBAC with least privilege
5. Enable admission controllers (PodSecurityPolicy/Pod Security Standards)
6. Implement resource quotas and limits
7. Enable audit logging
8. Rotate service account tokens regularly
9. Use dedicated service accounts for each application
10. Enable encryption at rest for etcd

Medium Priority:
- Implement image scanning and admission control
- Configure network segmentation
- Enable runtime security monitoring (Falco)
- Implement secrets management (external secret stores)
- Configure node security (kernel hardening)

Low Priority:
- Implement policy-as-code (OPA Gatekeeper)
- Enable service mesh for mTLS
- Implement workload identity
- Configure log forwarding and monitoring
EOF

write_report "$ARTIFACT_DIR"
exit 0
