# Changelog

All notable changes to the Ginnie Cybersecurity Toolkit will be documented in this file.

## [1.0.0] - 2025-09-10

### Added
- Initial release of Ginnie Cybersecurity Toolkit
- External reconnaissance module (nmap, httpx, passive DNS, testssl.sh)
- Web application security module (ZAP baseline, Nuclei safe templates)
- Cloud security audit module (ScoutSuite, Prowler, bucket guard, IAM lint)
- Internal network mapping module (Tailscale health, container scanning)
- Code security module (Gitleaks, detect-secrets, Semgrep, SBOM)
- SaaS security modules (Google Workspace, Bitwarden, MediaWiki guards)
- Comprehensive CLI dispatcher with scenario-based execution
- Authorization and ROE enforcement system
- Report templating and normalization
- Safe configuration profiles for all tools
- Kali Linux automated setup script
- Production-ready documentation and playbooks

### Security
- All modules enforce strict authorization checks
- Scope validation prevents unauthorized scanning
- Maintenance window compliance
- Secret redaction in reports
- Rate limiting and throttling controls
- No destructive testing by default

### Documentation
- Quick start guide
- Detailed playbooks for common scenarios
- ROE template and compliance guidelines
- Tool-specific configuration examples
