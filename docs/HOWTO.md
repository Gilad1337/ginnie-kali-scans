# Ginnie Cybersecurity Toolkit - HOWTO

## Prerequisites
- Bash, jq, yq, nmap, httpx, testssl.sh, sslyze, nuclei, ZAP, ScoutSuite, Prowler, Trivy, Docker Bench, Lynis, Gitleaks, detect-secrets, Semgrep, Syft, Grype
- Ensure ROE and scopes are present and valid

## Usage

### Example Commands
1. External surface mapping (safe):
   ```bash
   ./cli/run.sh --scenario external_recon --targets config/scopes.example.yaml --rate-limit 50
   ```
2. Web app passive baseline (ZAP):
   ```bash
   ./cli/run.sh --scenario external_web_zap --targets config/scopes.example.yaml --mode passive
   ```
3. GCP misconfiguration audit:
   ```bash
   ./cli/run.sh --scenario cloud_gcp_audit --project ginnie-prod --rate-limit 30
   ```
4. Internal VPN inventory over Tailscale (authorized):
   ```bash
   ./cli/run.sh --scenario internal_vpn_map --tailscale-range 100.64.0.0/10 --mode passive
   ```
5. Containers & hosts (Trivy, Docker Bench, Lynis – report only):
   ```bash
   ./cli/run.sh --scenario internal_container_scan --targets config/scopes.example.yaml
   ```

## Safety Notes
- Always verify authorization and scope before running any scan
- Only run during approved maintenance windows
- No destructive tests; passive/low-impact by default
- All findings must include evidence, impact, and remediation steps
- Redact secrets before sharing reports
