# Ginnie Cybersecurity Toolkit - Playbooks

## Common Scenarios

### 1. Onsite Assessment via Tailscale
- Ensure ROE and scopes are valid
- Run internal_vpn_map and container_node_scan
- Review findings and remediation steps

### 2. External Reconnaissance
- Use external_recon and external_tls
- Map exposed services, check TLS configs

### 3. Web Application Baseline
- Run external_web_zap and nuclei_safe
- Passive scan only, export reports

### 4. Cloud Audit (GCP)
- Use cloud_gcp_audit, bucket_guard, iam_lint
- Identify misconfigs, public assets, IAM outliers

### 5. Code & Secrets Review
- Run code_secrets, sast, sbom_cves
- Check for exposed secrets, code flaws, vulnerable dependencies

---
*Always follow ROE and safety guardrails. Document all findings and remediation steps.*
