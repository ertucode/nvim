#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command>"
    exit 1
fi

open -Fna "Ghostty" --args \
    --fullscreen=false \
    --window-save-state=never \
    --window-width=100 \
    --window-height=30 \
    --window-position-x=430 \
    --window-position-y=275 \
    -e /bin/zsh -lc "$*"
