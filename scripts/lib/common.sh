#!/usr/bin/env bash
# common.sh - Shared utilities for scanstack scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

resolve_target() {
    local path="${1:-$(pwd)}"
    (cd "$path" 2>/dev/null && pwd) || {
        echo "ERROR: path not found: $path" >&2
        exit 1
    }
}

project_name() {
    basename "$1"
}

date_str() {
    date +%Y-%m-%d
}

run_id() {
    local short_uuid; short_uuid="$(uuidgen | cut -c1-8)"
    echo "${short_uuid}-$(date_str)"
}

default_output_dir() {
    local target="$1"
    local script_dir="$2"
    local project; project="$(project_name "$target")"
    local rid; rid="$(run_id)"
    echo "$(cd "$script_dir/.." && pwd)/results/$project/$rid"
}

log_tool_start() {
    local tool="$1"
    echo -e "\n${BLUE}${BOLD}━━━ [$tool] ━━━${NC}"
}

log_tool_result() {
    local tool="$1"
    local exit_code="$2"
    local output_file="$3"
    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ [$tool] PASSED${NC} → $(basename "$output_file")"
    else
        echo -e "${RED}${BOLD}✗ [$tool] ISSUES FOUND (exit: $exit_code)${NC} → $(basename "$output_file")"
    fi
}

log_skip() {
    local tool="$1"
    local reason="$2"
    echo -e "${YELLOW}${BOLD}⚠ [$tool] SKIPPED${NC}: $reason"
}
