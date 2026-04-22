#!/usr/bin/env bash
# scripts/finalize.sh --- write uninstall.sh, clean up the build dir if it's
# outside $ME_PREFIX, print a version-checks summary.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
run_finalize
