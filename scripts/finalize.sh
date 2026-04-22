#!/usr/bin/env bash
# scripts/finalize.sh --- write uninstall.sh, clean up the build dir if it's
# outside $ME_PREFIX, print a version-checks summary.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
# pick_build_dir so cleanup_build_on_success knows what to remove (noop if the
# build dir was never used).
pick_build_dir
run_finalize
