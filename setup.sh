#!/usr/bin/env bash
# setup.sh --- orchestrator for the full install.
#
# Target: MIT ORCD (Rocky Linux 8.10+). Not portable to other distros.
#
# Thin wrapper around scripts/lib.sh — all the real logic lives there.
# You can run any single phase standalone:
#
#   bash scripts/preflight.sh
#   bash scripts/install_deps.sh
#   bash scripts/install_tools.sh
#   bash scripts/install_langs.sh
#   bash scripts/install_shell.sh
#   bash scripts/finalize.sh
#
# For interactive debugging, source lib.sh once and call any function by name:
#
#   source scripts/lib.sh
#   parse_flags                # optional; defaults stand
#   run_install_deps           # self-preps (preflight, mkdir, pick_build_dir)
#   install_ncurses            # or any single install_* function
#                              # (call `_phase_prep` first if you haven't
#                              # already run a run_* function this session)
#
# Layout ($ME_PREFIX defaults to $HOME/.melocal):
#   $ME_PREFIX/
#   ├── bin/                          installed tool binaries
#   ├── opt/{libevent,ncurses,openssl,curl,helix}/    isolated prefixes
#   ├── repo/                         the dotfiles repo
#   ├── zprezto/ powerlevel10k/       zsh theme machinery
#   ├── fnm/ bun/ python-default/     runtime installs
#   ├── tmux-plugins/                 TPM + installed plugins
#   ├── src/                          build workspace (removed on success)
#   ├── manifest.txt                  list of $HOME/.<rc> symlinks created
#   └── uninstall.sh                  self-extracting cleanup
#
# Strip + reinstall:
#   bash $HOME/.melocal/uninstall.sh && bash /path/to/setup.sh
#
# Usage:
#   bash setup.sh [--prefix=DIR] [--src=DIR] [--offline] [--verify-hashes]
#                 [--skip-deps] [--skip-tools] [--skip-langs] [--skip-shell]
#                 [--force-rebuild[=PKG]]

set -euo pipefail
umask 022

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$HERE/scripts/lib.sh"

parse_flags "$@"

# Full-reset shortcut: --force-rebuild (no argument) runs a pre-existing
# uninstaller before proceeding.
if [[ "$FORCE_REBUILD_ALL" == 1 && -x "$ME_PREFIX/uninstall.sh" ]]; then
    info "--force-rebuild: running prior uninstall.sh"
    bash "$ME_PREFIX/uninstall.sh" || true
fi

[[ "$SKIP_DEPS"  == 1 ]] || run_install_deps
[[ "$SKIP_TOOLS" == 1 ]] || run_install_tools
[[ "$SKIP_LANGS" == 1 ]] || run_install_langs

if [[ "$SKIP_SHELL" != 1 ]]; then
    # Let clone_or_update_repo link the local repo rather than re-cloning.
    export REPO_LOCAL_CHECKOUT="$HERE"
    run_install_shell
fi

run_finalize
