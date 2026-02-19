# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A security reviewer that runs a battery of static analysis tools against an external project directory. It is not a library — it is a collection of shell scripts that wrap security tools, store structured results, and produce a per-run summary.

The target of a scan is always an **external project**, not this repo itself.

## Setup

```bash
bash setup.sh          # one-time: creates conda env + pulls Docker image + installs pip tools
conda activate scanstack
```

Prerequisites: `conda`, `docker` (daemon must be running).

On Linux with Docker Desktop the daemon does not start automatically:
```bash
systemctl --user start docker-desktop
```

## Running scans

```bash
# Full review (all 7 tools)
./scripts/run_all.sh --path /path/to/project

# Single tool
./scripts/01_gitleaks.sh /path/to/project
./scripts/02_bandit.sh   /path/to/project
# etc.
```

Results land at `results/<project_name>/<YYYY-MM-DD>/` relative to this repo.

## Architecture

### Script calling convention

Every individual script (`01_` – `07_`) accepts two positional arguments:

```
$1  TARGET   — absolute path to the project being scanned
$2  OUTPUT_DIR — absolute path where results for this run are stored
```

When `$2` is omitted (standalone invocation), the script computes `OUTPUT_DIR` itself via `default_output_dir()` from `scripts/lib/common.sh`. When called by `run_all.sh`, both arguments are always passed so all tools write into the same dated directory.

### Output per tool

Each script writes up to two files into `OUTPUT_DIR`:
- `<tool>.json` (or `.md`/`.csv` for pip-licenses) — structured output for parsing
- `<tool>.log` — raw stdout/stderr for human review

`run_all.sh` adds a `summary.txt` after all tools finish.

### Exit code semantics

Exit code `0` = clean. Non-zero = findings (not an error). `run_all.sh` uses `set +e` around each step so a finding in one tool never aborts the rest. The overall exit code of `run_all.sh` is `1` if any tool reported findings.

`detect-secrets` is an exception: it always exits `0`, so `03_detect_secrets.sh` inspects the JSON and synthesises a non-zero exit code if `results.*` contains any entries.

### Shared utilities (`scripts/lib/common.sh`)

Sourced by every script. Provides: `resolve_target`, `project_name`, `date_str`, `default_output_dir`, `log_tool_start`, `log_tool_result`, `log_skip`. All colour output lives here.

## Key decisions

**gitleaks runs via Docker** (`ghcr.io/gitleaks/gitleaks:latest`), not installed into the conda env. Reason: gitleaks is a Go binary not published to any conda channel. Building from source inside conda requires a CGO-compatible C compiler (`x86_64-conda-linux-gnu-cc`) that conda's Go package does not bundle. Docker was simpler and is the official distribution method. The script mounts `TARGET` as `/repo:ro` and `OUTPUT_DIR` as `/output` so the JSON report lands directly in the right place.

**Python tools use a two-phase pip install.** Installing all five tools in one `pip install` command causes the resolver to backtrack indefinitely on semgrep's dependency tree. The fix: install `bandit`, `detect-secrets`, `pip-audit`, `pip-licenses` first, then `semgrep` alone, then pin `tomli>=2.2.1` back up (semgrep downgrades it). This leaves a pip resolver warning (`semgrep requires tomli~=2.0.1`) which is **expected and non-fatal** — semgrep's tomli pin is overly conservative; both tools work with tomli 2.4.0 at runtime.

**`set -uo pipefail` without `-e` in individual scripts.** Security tools exit non-zero when they find issues — that is the expected success path, not an error. Using `-e` would cause the script to abort before `log_tool_result` runs.

**`pip-licenses` scans the current environment, not the target project.** For accurate results the target's dependencies must be installed in the `scanstack` env before running `06_pip_licenses.sh`.

## Adding a new tool

1. Create `scripts/0N_toolname.sh` following the same two-argument pattern.
2. Source `lib/common.sh`, call `log_tool_start` / `log_tool_result`.
3. Write structured output to `$OUTPUT_DIR/toolname.json` and logs to `$OUTPUT_DIR/toolname.log`.
4. Exit with the tool's own exit code.
5. Register it in `run_all.sh`: add a `run_step` call and add the key to the `TOOLS` array.
