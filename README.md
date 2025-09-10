# Ginnie Cybersecurity Toolkit

Advanced penetration testing and security assessment suite for Ginnie Smart Homes infrastructure.

## Features

- **External Reconnaissance**: Web reconnaissance, subdomain enumeration, port scanning
- **Web Application Security**: OWASP ZAP baseline scans, Nuclei vulnerability detection
- **Cloud Security**: GCP misconfigurations, bucket auditing, IAM analysis
- **Internal Network**: Tailscale VPN mapping, container security scanning
- **Code Security**: Secret detection, SAST analysis, SBOM generation
- **SaaS Security**: Workspace, Bitwarden, and MediaWiki security audits

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd ginnie-kali-scans

# Run setup script
chmod +x setup.sh
./setup.sh

# Configure authorization
cp AUTHORIZATION/authorization.example.json AUTHORIZATION/authorization.json
# Edit authorization.json with your specific scope and permissions
```

## Quick Start

```bash
# External reconnaissance
./cli/run.sh --scenario external_recon --targets config/scopes.yaml --rate-limit 50

# Web application baseline scan
./cli/run.sh --scenario external_web_zap --targets config/scopes.yaml --mode passive

# GCP cloud audit
./cli/run.sh --scenario cloud_gcp_audit --project ginnie-prod

# Internal network mapping
./cli/run.sh --scenario internal_vpn_map --tailscale-range 100.64.0.0/10

# Code security scan
./cli/run.sh --scenario code_secrets
```

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md)
- [Playbooks](docs/PLAYBOOKS.md)
- [ROE Template](docs/ROE_TEMPLATE.md)

## Legal & Compliance

This toolkit enforces strict authorization controls:
- All scans require valid ROE (Rules of Engagement)
- Only authorized targets and time windows are allowed
- No destructive testing without explicit permission
- Compliant with ISO 27001, CIS Controls, NIST SP 800-115

## License

Proprietary - Ginnie Smart Homes Internal Use Only
# ginnie-kali-scans
