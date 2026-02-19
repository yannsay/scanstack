#!/usr/bin/env bash
# setup.sh — One-time setup for scanstack
#
# Installs:
#   1. conda environment 'scanstack' (Python 3.11 + Node.js)
#   2. gitleaks Docker image (ghcr.io/gitleaks/gitleaks:latest)
#   3. Python security tools via pip (bandit, detect-secrets, pip-audit,
#      pip-licenses, semgrep) — installed in two phases to avoid conflicts
#
# Usage: bash setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Conda environment ──────────────────────────────────────────────────────
echo "==> [1/3] Creating conda environment 'scanstack'..."
if conda env list | grep -q "^scanstack "; then
    echo "    Environment already exists — updating..."
    conda env update -f "$SCRIPT_DIR/environment.yml" --prune
else
    conda env create -f "$SCRIPT_DIR/environment.yml"
fi

# ── 2. gitleaks Docker image ──────────────────────────────────────────────────
echo ""
echo "==> [2/3] Pulling gitleaks Docker image..."
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi
if ! docker info &>/dev/null; then
    echo "    Docker daemon not running — starting Docker Desktop..."
    systemctl --user start docker-desktop
    echo -n "    Waiting for Docker to be ready..."
    for i in $(seq 1 30); do
        sleep 2
        if docker info &>/dev/null; then
            echo " ready."
            break
        fi
        echo -n "."
        if [ "$i" -eq 30 ]; then
            echo ""
            echo "ERROR: Docker did not start in time. Try: systemctl --user start docker-desktop"
            exit 1
        fi
    done
fi
docker pull ghcr.io/gitleaks/gitleaks:latest
echo "    gitleaks image ready."

# ── 3. Python security tools via pip ─────────────────────────────────────────
echo ""
echo "==> [3/3] Installing Python security tools via pip..."

# Step A: install all tools except semgrep — this pins tomli>=2.2.1 (pip-audit requirement)
conda run -n scanstack pip install \
    "bandit[toml]" \
    detect-secrets \
    pip-audit \
    pip-licenses

# Step B: install semgrep in two sub-steps to avoid a tomli version conflict.
# Problem: semgrep declares tomli~=2.0.1 (<2.1) but pip-audit requires tomli>=2.2.1.
#          Installing them together causes pip to backtrack indefinitely.
# Solution: let pip install semgrep and all its deps (including downgrading tomli),
#           then upgrade tomli back. Both tools work fine with tomli 2.4.0 at runtime
#           despite the declared conflict — semgrep's pin is overly conservative.
conda run -n scanstack pip install semgrep
conda run -n scanstack pip install "tomli>=2.2.1"
echo "    Note: pip will warn about semgrep's tomli constraint — this is expected and non-fatal."

echo ""
echo "==========================================="
echo " Setup complete!"
echo "==========================================="
echo ""
echo " Activate the environment:"
echo "   conda activate scanstack"
echo ""
echo " Run a full security review:"
echo "   ./scripts/run_all.sh --path /path/to/your/project"
echo ""
echo " Or run a single check, e.g.:"
echo "   ./scripts/01_gitleaks.sh /path/to/your/project"
