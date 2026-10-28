#!/usr/bin/env bash
set -euo pipefail
python3 "$1" --script "$2" --output "$3" --seconds 60
