#!/bin/bash
# Git repository initialization and setup script
set -euo pipefail

echo "Initializing Ginnie Cybersecurity Toolkit Git Repository..."

# Initialize git repository if not already done
if [[ ! -d .git ]]; then
    git init
    echo "✓ Git repository initialized"
fi

# Set up git configuration
git config --local user.name "Ginnie Security Team"
git config --local user.email "secops@ginnie.co.il"

# Stage all files for initial commit
git add .

# Create initial commit
if ! git rev-parse HEAD >/dev/null 2>&1; then
    git commit -m "Initial commit: Ginnie Cybersecurity Toolkit v1.0.0

- Complete penetration testing suite
- External reconnaissance and web security modules
- Cloud security audit capabilities (GCP)
- Internal network mapping via Tailscale
- Code security and secret detection
- SaaS security auditing
- Comprehensive authorization and compliance controls
- Production-ready for Kali Linux"
    echo "✓ Initial commit created"
fi

# Set up branch protection and workflows
echo "Repository setup complete!"
echo ""
echo "Next steps:"
echo "1. Push to remote repository:"
echo "   git remote add origin <your-repo-url>"
echo "   git push -u origin main"
echo ""
echo "2. Configure authorization:"
echo "   cp AUTHORIZATION/authorization.example.json AUTHORIZATION/authorization.json"
echo "   # Edit with your specific scope and permissions"
echo ""
echo "3. Run setup on target systems:"
echo "   ./setup.sh"
echo ""
echo "4. Start scanning:"
echo "   ./cli/run.sh --scenario external_recon --targets config/scopes.yaml"
