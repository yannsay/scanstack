#!/usr/bin/env bash
# 03_detect_secrets.sh — Additional secret detection using detect-secrets
# Usage: ./03_detect_secrets.sh [target_path] [output_dir]
#   target_path  Directory to scan (default: current directory)
#   output_dir   Where to store results (default: ../results/<project>/<date>/)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="detect-secrets"
TARGET="$(resolve_target "${1:-$(pwd)}")"

if [ -n "${2:-}" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$(default_output_dir "$TARGET" "$SCRIPT_DIR")"
fi
mkdir -p "$OUTPUT_DIR"

OUTPUT_JSON="$OUTPUT_DIR/detect_secrets.json"
OUTPUT_LOG="$OUTPUT_DIR/detect_secrets.log"

log_tool_start "$TOOL"
echo "  Source: $TARGET"

detect-secrets scan "$TARGET" \
    2>"$OUTPUT_LOG" \
    >"$OUTPUT_JSON"
EXIT_CODE=$?

# detect-secrets always exits 0 — check JSON for actual findings
if [ "$EXIT_CODE" -eq 0 ] && [ -f "$OUTPUT_JSON" ]; then
    SECRET_COUNT=$(python3 -c "
import json, sys
data = json.load(open('$OUTPUT_JSON'))
total = sum(len(v) for v in data.get('results', {}).values())
print(total)
" 2>/dev/null || echo "0")

    if [ "$SECRET_COUNT" -gt 0 ]; then
        echo "  Potential secrets detected: $SECRET_COUNT"
        EXIT_CODE=1
    else
        echo "  No secrets detected."
    fi
fi

log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_JSON"
exit $EXIT_CODE
