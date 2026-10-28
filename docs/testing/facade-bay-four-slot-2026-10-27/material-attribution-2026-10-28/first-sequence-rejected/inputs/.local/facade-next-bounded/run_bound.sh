#!/usr/bin/env bash
set -euo pipefail
# Arguments intentionally expose every .local transitive dependency to observer.
python3 "$1" --repo "$PWD" --output "$4" --execute
