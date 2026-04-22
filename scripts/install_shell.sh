#!/usr/bin/env bash
# scripts/install_shell.sh --- clone the dotfiles repo, install prezto + p10k,
# symlink dotfiles into $HOME, bootstrap TPM.
#
# If invoked from inside a local checkout, the repo is linked (not cloned) so
# edits to the tracked dotfiles propagate immediately.
set -euo pipefail
umask 022
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$HERE/lib.sh"
parse_flags "$@"
# Pass the local checkout so clone_or_update_repo can use it.
export REPO_LOCAL_CHECKOUT="${REPO_LOCAL_CHECKOUT:-$(cd "$HERE/.." && pwd)}"
run_install_shell
