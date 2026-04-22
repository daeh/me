#!/usr/bin/env bash
# scripts/install_deps.sh --- build libevent, ncurses, openssl, curl
# under $ME_PREFIX/opt/<pkg>. Idempotent; honors --force-rebuild[=pkg].
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
ensure_preflight
mkdir -p "$ME_PREFIX/bin" "$ME_PREFIX/opt"
pick_build_dir
run_install_deps
