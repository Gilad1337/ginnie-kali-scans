# Contributing to Ginnie Cybersecurity Toolkit

## Security First

This toolkit is designed for authorized security assessments only. All contributions must maintain:

- Strict authorization enforcement
- Safe-by-default configurations
- Compliance with legal and ethical guidelines
- No destructive testing capabilities

## Development Guidelines

### Adding New Modules

1. Create module directory under appropriate category:
   - `modules_external/` - External reconnaissance and testing
   - `modules_cloud_gcp/` - Google Cloud Platform security
   - `modules_internal_vpn/` - Internal network assessment
   - `modules_code_secrets/` - Code and secret analysis
   - `modules_saas_identity/` - SaaS and identity security

2. Include `run_module.sh` with standard structure:
   ```bash
   #!/bin/bash
   set -euo pipefail
   
   # Use shared functions
   source ../../lib/common.sh
   
   check_roe
   # ... module logic
   write_report "$ARTIFACT_DIR"
   ```

3. Add corresponding CLI scenario in `cli/run.sh`

### Configuration Standards

- All tools must have safe default configurations
- Rate limiting and throttling required
- Passive scanning preferred over active
- Clear documentation of tool capabilities

### Testing

- Test all modules with sample data
- Verify authorization enforcement
- Validate output normalization
- Check for secret leakage in reports

## Code Review Process

1. All changes require security review
2. Test with ROE validation disabled (should fail)
3. Verify no hardcoded credentials or endpoints
4. Ensure consistent error handling and logging

## Reporting Issues

- Security issues: Contact secops@ginnie.co.il privately
- Bugs and features: Use standard issue tracking
- Include ROE compliance impact in all reports
