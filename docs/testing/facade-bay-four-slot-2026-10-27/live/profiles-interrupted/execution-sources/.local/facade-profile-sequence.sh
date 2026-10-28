#!/usr/bin/env bash
set -euo pipefail
python3 "$1" --repo "$PWD" --runner "$2" --script "$3" --output "$PWD/.local/facade-four-slot-profile-six" --execute
python3 "$4" "$PWD/.local/facade-four-slot-profile-six/sequence.json" --output "$PWD/.local/facade-four-slot-profile-six/comparison.json"
