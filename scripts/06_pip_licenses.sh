#!/usr/bin/env bash
# 06_pip_licenses.sh — Check Python dependency licenses for GPL/AGPL
# Usage: ./06_pip_licenses.sh [target_path] [output_dir]
#   target_path  (informational) project being reviewed
#   output_dir   Where to store results (default: ../results/<project>/<date>/)
# Note: Scans packages installed in the CURRENT Python environment.
#       For accurate results, install the target project's dependencies first:
#         pip install -r <target>/requirements.txt

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="pip-licenses"
TARGET="$(resolve_target "${1:-$(pwd)}")"

if [ -n "${2:-}" ]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$(default_output_dir "$TARGET" "$SCRIPT_DIR")"
fi
mkdir -p "$OUTPUT_DIR"

OUTPUT_MD="$OUTPUT_DIR/pip_licenses.md"
OUTPUT_CSV="$OUTPUT_DIR/pip_licenses.csv"
OUTPUT_LOG="$OUTPUT_DIR/pip_licenses.log"

log_tool_start "$TOOL"
echo "  Scanning current Python environment"

pip-licenses \
    --format=markdown \
    --with-urls \
    --with-description \
    >"$OUTPUT_MD" \
    2>"$OUTPUT_LOG"

pip-licenses \
    --format=csv \
    --with-urls \
    >"$OUTPUT_CSV" \
    2>>"$OUTPUT_LOG"

# Flag GPL/AGPL licenses (exclude the header row)
FLAGGED=$(grep -iE "(GPL|AGPL)" "$OUTPUT_MD" | grep -v "^| Name\|^|---" || true)
EXIT_CODE=0

if [ -n "$FLAGGED" ]; then
    echo -e "\n  ${RED}GPL/AGPL licenses detected:${NC}"
    echo "$FLAGGED" | sed 's/^/    /'
    EXIT_CODE=1
else
    echo "  No GPL/AGPL licenses detected."
fi

log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_MD"
exit $EXIT_CODE
