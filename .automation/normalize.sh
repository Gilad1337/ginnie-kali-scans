#!/bin/bash
# Normalize and redact secrets in reports
set -euo pipefail

# Usage: ./normalize.sh <artifact_dir>
ARTIFACT_DIR="$1"

# Redact secrets, tokens, emails (stub)
find "$ARTIFACT_DIR" -type f -name '*.md' -o -name '*.json' | while read -r file; do
  sed -i '' -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[REDACTED_EMAIL]/g' "$file"
  sed -i '' -E 's/(token|secret|password)[^\s"]+/[REDACTED_SECRET]/gi' "$file"
  # ...add more patterns as needed...
done

echo "Normalization complete."
