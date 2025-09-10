# Ginnie Cybersecurity Toolkit - Quickstart Guide

## 1. Prerequisites
- Install: bash, jq, yq, nmap, httpx, testssl.sh, sslyze, nuclei, ZAP, ScoutSuite, Prowler, Trivy, Docker Bench, Lynis, Gitleaks, detect-secrets, Semgrep, Syft, Grype
- Ensure `/AUTHORIZATION/authorization.json` and `/config/scopes.yaml` are filled out and valid
- Set up environment variables in `/cli/env.example`

## 2. Running an Assessment
- All scans must be run within authorized maintenance windows and scope
- Use the CLI dispatcher:

```bash
./cli/run.sh --scenario external_recon --targets config/scopes.example.yaml --rate-limit 50
./cli/run.sh --scenario cloud_gcp_audit --project ginnie-prod --rate-limit 30
./cli/run.sh --scenario internal_vpn_map --tailscale-range 100.64.0.0/10 --mode passive
./cli/run.sh --scenario code_secrets
./cli/run.sh --scenario external_web_zap --targets config/scopes.example.yaml --mode passive
```

## 3. Reviewing Results
- All findings and reports are saved in `/reports/artifacts/<timestamp>/`
- Use `/reports/templates/report.md` and `/reports/templates/finding.json` for consistent reporting
- Run `.automation/normalize.sh <artifact_dir>` to redact secrets before sharing

## 4. Validation Steps for Production
- Confirm all required tools are installed and in `$PATH`
- Validate ROE and scopes are present and correct
- Run `.automation/preflight.sh` before any scan
- Ensure all modules exit if not authorized or out of scope
- Review `/docs/HOWTO.md` and `/docs/PLAYBOOKS.md` for scenario guidance
- Test each module runner with sample data and verify output normalization

## 5. Optimization Notes
- All module runners use shared functions for ROE checks and report writing
- No repeated code; logic is modular and maintainable
- All scans are throttled and passive by default for safety

---
*For support, contact secops@ginnie.co.il*
