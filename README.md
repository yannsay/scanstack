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
