#!/usr/bin/env bash
# scripts/install_tools.sh --- zsh, tmux, vim, git (source) + jj, task, helix
# (prebuilt binaries) into $ME_PREFIX/bin. Assumes deps already built.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
run_install_tools
