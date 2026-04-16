#!/bin/bash
# system-snapshot.sh — writes host system version info to Artoo's workspace
# Run via host cron at 5:45am daily (before 6am Agent Needs Briefing)
# Output: ~/openclaw/workspace/tmp/system-snapshot.txt

set -euo pipefail

OUT=~/openclaw/workspace/tmp/system-snapshot.txt
TIMESTAMP=$(date '+%Y-%m-%d %H:%M %Z')

{
  echo "# System Snapshot"
  echo "Generated: $TIMESTAMP"
  echo ""

  echo "## DGX OS"
  if [[ -f /etc/dgx-release ]]; then
    installed=$(grep DGX_OTA_VERSION /etc/dgx-release | tail -1 | cut -d'"' -f2)
    build=$(grep DGX_SWBUILD_VERSION /etc/dgx-release | cut -d'"' -f2)
    echo "Installed (OTA): ${installed:-unknown}"
    echo "Build version:   ${build:-unknown}"
  fi
  candidate=$(apt-cache policy dgx-release 2>/dev/null | grep Candidate | awk '{print $2}')
  echo "Latest available: ${candidate:-unknown}"
  if [[ -n "$candidate" && -n "${installed:-}" && "$candidate" != "$installed" ]]; then
    echo "⚠️ Update available: $installed → $candidate"
  else
    echo "✅ Up to date"
  fi
  echo ""

  echo "## NVIDIA Driver"
  driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
  echo "Installed: ${driver:-unknown}"
  echo ""

  echo "## CUDA"
  cuda=$(nvcc --version 2>/dev/null | grep -oP 'release \K[\d.]+')
  echo "Installed: ${cuda:-unknown}"
  echo ""

  echo "## Kernel"
  echo "Installed: $(uname -r)"
  echo ""

  echo "## Docker"
  echo "Installed: $(docker --version 2>/dev/null | grep -oP 'version \K[\d.]+')"
  echo ""

  echo "## Ollama (container)"
  ollama_ver=$(docker exec ollama ollama --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
  echo "Installed: ${ollama_ver:-unknown}"
  echo ""

  echo "## OpenClaw (container)"
  oc_ver=$(docker exec openclaw-gateway node openclaw.mjs --version 2>/dev/null | grep -oP '[\d.]+')
  echo "Installed: ${oc_ver:-unknown}"

} > "$OUT"

echo "[system-snapshot] wrote $OUT at $TIMESTAMP"
