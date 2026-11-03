#!/usr/bin/env bash
# Restart GameLog. Flags are passed to start.sh (e.g. --prod).
set -euo pipefail
cd "$(dirname "$0")"

./stop.sh
./start.sh "$@"
