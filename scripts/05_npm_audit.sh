#!/usr/bin/env bash
# 05_npm_audit.sh — Node.js dependency CVE audit using npm audit
# Usage: ./05_npm_audit.sh [target_path] [output_dir]
#   target_path  Project directory containing package.json
#   output_dir   Where to store results (default: ../results/<project>/<date>/)
# Note: Skipped automatically if no package.json is found.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="npm-audit"
TARGET="$(resolve_target "${1:-$(pwd)}")"

if [ -n "${2:-}" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$(default_output_dir "$TARGET" "$SCRIPT_DIR")"
fi
mkdir -p "$OUTPUT_DIR"

OUTPUT_JSON="$OUTPUT_DIR/npm_audit.json"
OUTPUT_LOG="$OUTPUT_DIR/npm_audit.log"

log_tool_start "$TOOL"
echo "  Source: $TARGET"

if [ ! -f "$TARGET/package.json" ]; then
    log_skip "$TOOL" "No package.json found in $TARGET"
    echo '{"skipped": true, "reason": "No package.json found"}' >"$OUTPUT_JSON"
    exit 0
fi

(cd "$TARGET" && npm audit --json) \
    2>"$OUTPUT_LOG" \
    >"$OUTPUT_JSON"
EXIT_CODE=$?

log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_JSON"
exit $EXIT_CODE
