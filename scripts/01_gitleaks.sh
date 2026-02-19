#!/usr/bin/env bash
# 01_gitleaks.sh — Scan for hardcoded secrets using gitleaks (via Docker)
# Usage: ./01_gitleaks.sh [target_path] [output_dir]
#   target_path  Directory to scan (default: current directory)
#   output_dir   Where to store results (default: ../results/<project>/<date>/)
# Requires: Docker (image ghcr.io/gitleaks/gitleaks:latest)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TOOL="gitleaks"
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

docker run --rm \
    -v "$TARGET:/repo:ro" \
    -v "$OUTPUT_DIR:/output" \
    ghcr.io/gitleaks/gitleaks:latest \
    detect \
    --source /repo \
    --report-format json \
    --report-path /output/gitleaks.json \
    2>&1 | tee "$OUTPUT_LOG"
EXIT_CODE=${PIPESTATUS[0]}

log_tool_result "$TOOL" "$EXIT_CODE" "$OUTPUT_JSON"
exit $EXIT_CODE
