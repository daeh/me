#!/usr/bin/env bash
# scripts/install_langs.sh --- uv, fnm + Node LTS + yarn (corepack), bun,
# the default Python venv, and rmate.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
run_install_langs
