#!/usr/bin/env bash
# 02_bandit.sh — Python security static analysis using bandit
# Usage: ./02_bandit.sh [target_path] [output_dir]
#   target_path  Python project directory to scan (default: current directory)
#   output_dir   Where to store results (default: ../results/<project>/<date>/)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="bandit"
TARGET="$(resolve_target "${1:-$(pwd)}")"

if [ -n "${2:-}" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$(default_output_dir "$TARGET" "$SCRIPT_DIR")"
fi
mkdir -p "$OUTPUT_DIR"

OUTPUT_JSON="$OUTPUT_DIR/${TOOL}.json"
OUTPUT_LOG="$OUTPUT_DIR/${TOOL}.log"

log_tool_start "$TOOL"
echo "  Source: $TARGET"

bandit \
    -r "$TARGET" \
    -f json \
    -o "$OUTPUT_JSON" \
    2>&1 | tee "$OUTPUT_LOG"
EXIT_CODE=${PIPESTATUS[0]}

# bandit exits 1 when issues are found (not an error, expected behavior)
log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_JSON"
exit $EXIT_CODE
