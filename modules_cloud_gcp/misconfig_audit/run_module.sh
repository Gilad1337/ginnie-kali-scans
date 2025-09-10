#!/bin/bash
# GCP Misconfiguration Audit module runner (stub)
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
  echo "{}" > "$dir/findings.json"
  echo "# GCP Audit Report" > "$dir/report.md"
}

# Main logic
check_roe
PROJECTS=$(yq '.environments.production.gcp_projects[]' ../../config/scopes.example.yaml)
ARTIFACT_DIR="../../reports/artifacts/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARTIFACT_DIR"

for project in $PROJECTS; do
  echo "Running ScoutSuite for $project..."
  ScoutSuite -p "$project" >> "$ARTIFACT_DIR/scoutsuite.txt" 2>&1
  echo "Running Prowler for $project..."
  prowler -p "$project" >> "$ARTIFACT_DIR/prowler.txt" 2>&1
done

# CIS gap map, IAM outliers (stub)
echo "CIS gap map (see ScoutSuite/Prowler output)" > "$ARTIFACT_DIR/cis_gap.txt"
echo "IAM outliers (see ScoutSuite/Prowler output)" > "$ARTIFACT_DIR/iam_outliers.txt"

write_report "$ARTIFACT_DIR"

exit 0
