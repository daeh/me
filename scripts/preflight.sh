#!/usr/bin/env bash
# scripts/preflight.sh --- run pre-flight checks (OS, Lmod, toolchain, network).
# Safe to run standalone. Sets PREFLIGHT_DONE=1 in the current shell if sourced.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
run_preflight
