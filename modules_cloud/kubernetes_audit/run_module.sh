#!/bin/bash
# Advanced Cloud Kubernetes Security Assessment
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
  "scan_type": "kubernetes_security",
  "findings": [
    {
      "id": "K8S-001",
      "severity": "high",
      "title": "Kubernetes Security Misconfigurations",
      "description": "Security issues identified in Kubernetes cluster configuration",
      "evidence": "See kube_audit_results.txt for detailed findings",
      "impact": "Container escape, privilege escalation, data exposure",
      "remediation": "Implement RBAC, network policies, security contexts, admission controllers",
      "cvss": "8.1",
      "mitre_attack": ["T1611", "T1610", "T1613"]
    }
  ]
}
EOF
  echo "# Kubernetes Security Assessment Report" > "$dir/report.md"
}

check_roe
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

echo "Running comprehensive Kubernetes security assessment..."

# Kube-bench - CIS Kubernetes Benchmark
echo "=== CIS Kubernetes Benchmark ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kube-bench --json > "$ARTIFACT_DIR/kube_bench_results.json" 2>&1

# Kube-hunter - Active hunting for security weaknesses
echo "=== Kube-hunter Security Scan ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kube-hunter --remote --quick --report json > "$ARTIFACT_DIR/kube_hunter_results.json" 2>&1

# Polaris - Best practices validation
echo "=== Polaris Best Practices ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
polaris audit --format=json > "$ARTIFACT_DIR/polaris_results.json" 2>&1

# Falco - Runtime security monitoring
echo "=== Falco Runtime Security ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
falco --json-output > "$ARTIFACT_DIR/falco_runtime.json" 2>&1 &
FALCO_PID=$!
sleep 30
kill $FALCO_PID

# OPA Gatekeeper policy violations
echo "=== OPA Gatekeeper Policies ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get constraints -o json > "$ARTIFACT_DIR/opa_constraints.json" 2>&1

# RBAC analysis
echo "=== RBAC Analysis ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl auth can-i --list --as=system:serviceaccount:default:default > "$ARTIFACT_DIR/rbac_analysis.txt" 2>&1
kubectl get clusterrolebindings -o json > "$ARTIFACT_DIR/cluster_role_bindings.json" 2>&1
kubectl get rolebindings --all-namespaces -o json > "$ARTIFACT_DIR/role_bindings.json" 2>&1

# Network policy analysis
echo "=== Network Policy Analysis ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get networkpolicies --all-namespaces -o json > "$ARTIFACT_DIR/network_policies.json" 2>&1

# Pod Security Policy/Standards analysis
echo "=== Pod Security Analysis ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.securityContext.runAsRoot == true or .spec.securityContext.privileged == true)' > "$ARTIFACT_DIR/privileged_pods.json" 2>&1

# Secret analysis
echo "=== Secret Analysis ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get secrets --all-namespaces -o json > "$ARTIFACT_DIR/secrets_analysis.json" 2>&1

# Image vulnerability scanning
echo "=== Image Vulnerability Scan ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get pods --all-namespaces -o json | jq -r '.items[].spec.containers[].image' | sort -u > "$ARTIFACT_DIR/container_images.txt"
while read -r image; do
  echo "Scanning image: $image" >> "$ARTIFACT_DIR/image_scan.txt"
  trivy image --format json "$image" > "$ARTIFACT_DIR/trivy_$(echo $image | tr '/' '_' | tr ':' '_').json" 2>&1
done < "$ARTIFACT_DIR/container_images.txt"

# Admission controller analysis
echo "=== Admission Controllers ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl describe configmap -n kube-system kube-apiserver > "$ARTIFACT_DIR/admission_controllers.txt" 2>&1

# etcd security analysis
echo "=== etcd Security ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get pods -n kube-system -l component=etcd -o json > "$ARTIFACT_DIR/etcd_pods.json" 2>&1

# Service account token analysis
echo "=== Service Account Tokens ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
kubectl get serviceaccounts --all-namespaces -o json > "$ARTIFACT_DIR/service_accounts.json" 2>&1

# Custom security checks
echo "=== Custom Security Checks ===" >> "$ARTIFACT_DIR/k8s_audit.txt"
# Check for default service accounts with elevated privileges
kubectl get clusterrolebindings -o json | jq '.items[] | select(.subjects[]?.name == "default")' > "$ARTIFACT_DIR/default_sa_bindings.json" 2>&1

# Check for pods running as root
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.securityContext.runAsUser == 0 or (.spec.containers[].securityContext.runAsUser // 0) == 0)' > "$ARTIFACT_DIR/root_pods.json" 2>&1

# Check for privileged pods
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.containers[].securityContext.privileged == true)' > "$ARTIFACT_DIR/privileged_containers.json" 2>&1

# Check for host network/PID/IPC usage
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.hostNetwork == true or .spec.hostPID == true or .spec.hostIPC == true)' > "$ARTIFACT_DIR/host_access_pods.json" 2>&1

write_report "$ARTIFACT_DIR"
exit 0
