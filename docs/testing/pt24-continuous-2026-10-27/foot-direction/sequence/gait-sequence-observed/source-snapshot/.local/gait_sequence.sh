#!/usr/bin/env bash
set -euo pipefail
timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/gait_sequence.gd
