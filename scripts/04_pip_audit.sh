#!/usr/bin/env bash
# 04_pip_audit.sh — Python dependency CVE audit using pip-audit
# Usage: ./04_pip_audit.sh [target_path] [output_dir]
#   target_path  Project directory containing requirements.txt or pyproject.toml
#   output_dir   Where to store results (default: ../results/<project>/<date>/)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="pip-audit"
TARGET="$(resolve_target "${1:-$(pwd)}")"

if [ -n "${2:-}" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$(default_output_dir "$TARGET" "$SCRIPT_DIR")"
fi
mkdir -p "$OUTPUT_DIR"

OUTPUT_JSON="$OUTPUT_DIR/pip_audit.json"
OUTPUT_LOG="$OUTPUT_DIR/pip_audit.log"

log_tool_start "$TOOL"
echo "  Source: $TARGET"

if [ -f "$TARGET/requirements.txt" ]; then
    echo "  Using: requirements.txt"
    pip-audit \
        -r "$TARGET/requirements.txt" \
        -f json \
        -o "$OUTPUT_JSON" \
        2>&1 | tee "$OUTPUT_LOG"
elif [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/setup.py" ]; then
    echo "  Using: pyproject.toml / setup.py"
    pip-audit \
        --local \
        -f json \
        -o "$OUTPUT_JSON" \
        2>&1 | tee "$OUTPUT_LOG"
else
    echo "  No requirements.txt or pyproject.toml found — auditing current environment"
    pip-audit \
        --local \
        -f json \
        -o "$OUTPUT_JSON" \
        2>&1 | tee "$OUTPUT_LOG"
fi
EXIT_CODE=${PIPESTATUS[0]}

log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_JSON"
exit $EXIT_CODE
