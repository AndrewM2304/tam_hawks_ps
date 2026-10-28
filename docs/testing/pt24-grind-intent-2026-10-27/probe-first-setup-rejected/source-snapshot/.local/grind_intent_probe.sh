#!/usr/bin/env bash
set -euo pipefail
./tools/run.sh --headless --fixed-fps 60 --script "$1"
