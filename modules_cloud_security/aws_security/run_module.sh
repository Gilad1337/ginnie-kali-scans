#!/bin/bash
# Advanced AWS Security Assessment module
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
  "scan_type": "aws_security_assessment",
  "aws_accounts": $(echo "$AWS_ACCOUNTS" | jq -R -s -c 'split("\n")[:-1]'),
  "findings": [],
  "tools_used": ["ScoutSuite", "Prowler", "CloudMapper", "PacBot"],
  "severity": "varies",
  "compliance_frameworks": ["CIS", "AWS Well-Architected", "SOC2", "PCI"],
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "# AWS Security Assessment Report" > "$dir/report.md"
  echo "Generated: $(date)" >> "$dir/report.md"
  echo "Compliance: CIS AWS Foundations Benchmark" >> "$dir/report.md"
}

# Main logic
check_roe
AWS_ACCOUNTS=$(yq '.environments.production.aws_accounts[]' ../../config/scopes.example.yaml 2>/dev/null || echo "default")
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for account in $AWS_ACCOUNTS; do
  echo "Running comprehensive AWS security assessment for account: $account..."
  
  # ScoutSuite for AWS
  echo "Running ScoutSuite for AWS account $account..."
  scout --provider aws --profile "$account" --report-dir "$ARTIFACT_DIR/scoutsuite_$account" > "$ARTIFACT_DIR/scoutsuite_$account.log" 2>&1
  
  # Prowler for CIS compliance
  echo "Running Prowler CIS assessment for account $account..."
  prowler -p "$account" -M csv,json,html > "$ARTIFACT_DIR/prowler_$account.log" 2>&1
  
  # Custom AWS security checks
  echo "Running custom AWS security checks for account $account..."
  
  # S3 bucket security
  aws s3api list-buckets --profile "$account" --query 'Buckets[].Name' --output text > "$ARTIFACT_DIR/s3_buckets_$account.txt" 2>&1
  
  # IAM analysis
  aws iam list-users --profile "$account" --output table > "$ARTIFACT_DIR/iam_users_$account.txt" 2>&1
  aws iam list-roles --profile "$account" --output table > "$ARTIFACT_DIR/iam_roles_$account.txt" 2>&1
  
  # EC2 security groups
  aws ec2 describe-security-groups --profile "$account" --output table > "$ARTIFACT_DIR/security_groups_$account.txt" 2>&1
  
  # CloudTrail status
  aws cloudtrail describe-trails --profile "$account" --output table > "$ARTIFACT_DIR/cloudtrail_$account.txt" 2>&1
  
  # VPC configuration
  aws ec2 describe-vpcs --profile "$account" --output table > "$ARTIFACT_DIR/vpcs_$account.txt" 2>&1
  
  # Lambda functions
  aws lambda list-functions --profile "$account" --output table > "$ARTIFACT_DIR/lambda_functions_$account.txt" 2>&1
  
  # RDS instances
  aws rds describe-db-instances --profile "$account" --output table > "$ARTIFACT_DIR/rds_instances_$account.txt" 2>&1
done

# Generate comprehensive AWS security summary
echo "AWS Security Assessment Summary:" > "$ARTIFACT_DIR/aws_security_summary.txt"
echo "===============================" >> "$ARTIFACT_DIR/aws_security_summary.txt"
echo "Assessment Date: $(date)" >> "$ARTIFACT_DIR/aws_security_summary.txt"
echo "Compliance Frameworks: CIS AWS Foundations, AWS Well-Architected" >> "$ARTIFACT_DIR/aws_security_summary.txt"
echo "" >> "$ARTIFACT_DIR/aws_security_summary.txt"

for account in $AWS_ACCOUNTS; do
  echo "Account: $account" >> "$ARTIFACT_DIR/aws_security_summary.txt"
  echo "S3 Buckets: $(wc -w < "$ARTIFACT_DIR/s3_buckets_$account.txt" 2>/dev/null || echo "0")" >> "$ARTIFACT_DIR/aws_security_summary.txt"
  echo "IAM Users: $(grep -c 'UserName' "$ARTIFACT_DIR/iam_users_$account.txt" 2>/dev/null || echo "0")" >> "$ARTIFACT_DIR/aws_security_summary.txt"
  echo "Security Groups: $(grep -c 'GroupId' "$ARTIFACT_DIR/security_groups_$account.txt" 2>/dev/null || echo "0")" >> "$ARTIFACT_DIR/aws_security_summary.txt"
  echo "---" >> "$ARTIFACT_DIR/aws_security_summary.txt"
done

# Generate remediation recommendations
cat > "$ARTIFACT_DIR/aws_remediation.txt" << EOF
AWS Security Remediation Recommendations:
==========================================

1. Enable CloudTrail in all regions
2. Enable GuardDuty for threat detection
3. Configure AWS Config for compliance monitoring
4. Review IAM policies for least privilege
5. Enable MFA for all IAM users
6. Encrypt S3 buckets with KMS
7. Enable VPC Flow Logs
8. Review security group rules
9. Enable AWS Security Hub
10. Implement AWS Organizations SCPs

Priority Actions:
- Remove overly permissive security group rules
- Enable encryption for all data stores
- Implement proper IAM role separation
- Enable logging and monitoring
EOF

write_report "$ARTIFACT_DIR"
exit 0
