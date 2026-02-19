#!/usr/bin/env bash
# run_all.sh — Master security review orchestrator
# Runs all 7 scan steps and stores results per tool.
#
# Usage:
#   ./scripts/run_all.sh [--path <target_directory>]
#   ./scripts/run_all.sh /path/to/project
#
# Results are stored at:
#   sec_reviewer/results/<project_name>/<date>/

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
TARGET_PATH="$(pwd)"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --path|-p) TARGET_PATH="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--path <target_directory>]"
            exit 0 ;;
        *) TARGET_PATH="$1"; shift ;;
    esac
done

TARGET="$(resolve_target "$TARGET_PATH")"
PROJECT="$(project_name "$TARGET")"
DT="$(date_str)"
RESULTS_BASE="$(cd "$SCRIPT_DIR/.." && pwd)/results"
OUTPUT_DIR="$RESULTS_BASE/$PROJECT/$DT"

mkdir -p "$OUTPUT_DIR"

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║      SEC-REVIEWER — Full Scan        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo "  Target:  $TARGET"
echo "  Project: $PROJECT"
echo "  Date:    $DT"
echo "  Results: $OUTPUT_DIR"

# ── Run each step ─────────────────────────────────────────────────────────────
declare -A RESULTS

run_step() {
    local script="$1"
    local key="$2"
    set +e
    bash "$SCRIPT_DIR/$script" "$TARGET" "$OUTPUT_DIR"
    RESULTS[$key]=$?
    set -e
}

run_step "01_gitleaks.sh"       "gitleaks"
run_step "02_bandit.sh"         "bandit"
run_step "03_detect_secrets.sh" "detect-secrets"
run_step "04_pip_audit.sh"      "pip-audit"
run_step "05_npm_audit.sh"      "npm-audit"
run_step "06_pip_licenses.sh"   "pip-licenses"
run_step "07_semgrep.sh"        "semgrep"

# ── Summary ───────────────────────────────────────────────────────────────────
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
OVERALL=0

echo -e "\n${BOLD}━━━ SUMMARY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
{
    echo "Security Review Summary"
    echo "Project : $PROJECT"
    echo "Date    : $DT"
    echo "Target  : $TARGET"
    echo ""
    echo "Results:"
} >"$SUMMARY_FILE"

TOOLS=(gitleaks bandit detect-secrets pip-audit npm-audit pip-licenses semgrep)
for tool in "${TOOLS[@]}"; do
    code="${RESULTS[$tool]:-0}"
    if [ "$code" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC}  $tool"
        echo "  PASSED       $tool" >>"$SUMMARY_FILE"
    else
        echo -e "  ${RED}✗${NC}  $tool  (exit: $code)"
        echo "  ISSUES FOUND $tool  (exit: $code)" >>"$SUMMARY_FILE"
        OVERALL=1
    fi
done

echo "" >>"$SUMMARY_FILE"
echo "Results stored in: $OUTPUT_DIR" >>"$SUMMARY_FILE"

echo ""
echo "  Results → $OUTPUT_DIR"
echo "  Summary → $SUMMARY_FILE"

if [ "$OVERALL" -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}All checks passed.${NC}"
else
    echo -e "\n${RED}${BOLD}Issues found — review results above.${NC}"
fi

exit $OVERALL
