#!/usr/bin/env bash
# update.sh --- pull-and-refresh helper. Assumes setup.sh has already run.
#
# What it does:
#   - git pull in $ME_PREFIX/{repo,zprezto,powerlevel10k,tmux-plugins/tpm}
#   - uv self update
#   - fnm install --lts  (fetches any new LTS releases)
#   - bun upgrade
#   - jj version check against $ME_PREFIX/repo/setup.sh's pinned JJ_VERSION
#
# It does NOT rebuild zsh/tmux/vim/git/openssl/ncurses/libevent/curl — bump the
# version pins in setup.sh and run `bash setup.sh --force-rebuild=<pkg>` for that.

set -euo pipefail

ME_PREFIX="${ME_PREFIX:-$HOME/.melocal}"

if [[ ! -d "$ME_PREFIX" ]]; then
    echo "error: $ME_PREFIX not found; run setup.sh first" >&2
    exit 1
fi

info() { printf '==> %s\n' "$*"; }

pull_if_git() {
    local dir=$1
    if [[ -d "$dir/.git" ]]; then
        info "git pull $dir"
        git -C "$dir" pull --ff-only --recurse-submodules 2>/dev/null \
            || git -C "$dir" pull --ff-only
    else
        info "skip: $dir is not a git checkout"
    fi
}

pull_if_git "$ME_PREFIX/repo"
pull_if_git "$ME_PREFIX/zprezto"
git -C "$ME_PREFIX/zprezto" submodule update --init --recursive 2>/dev/null || true
pull_if_git "$ME_PREFIX/powerlevel10k"
pull_if_git "$ME_PREFIX/tmux-plugins/tpm"

if [[ -x "$ME_PREFIX/bin/uv" ]]; then
    info "uv self update"
    "$ME_PREFIX/bin/uv" self update || true
fi

if [[ -x "$ME_PREFIX/bin/fnm" ]]; then
    info "fnm install --lts (picks up any new LTS point release)"
    FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" install --lts || true
fi

if [[ -x "$ME_PREFIX/bun/bin/bun" ]]; then
    info "bun upgrade"
    BUN_INSTALL="$ME_PREFIX/bun" "$ME_PREFIX/bun/bin/bun" upgrade || true
fi

# jj is a pinned-version binary; check the installed version against the pin.
if [[ -x "$ME_PREFIX/bin/jj" && -r "$ME_PREFIX/repo/setup.sh" ]]; then
    local_pin=$(grep -oE 'JJ_VERSION=[0-9.]+' "$ME_PREFIX/repo/setup.sh" | head -1 | cut -d= -f2)
    local_installed=$("$ME_PREFIX/bin/jj" --version 2>/dev/null | awk '{print $2}' | head -1)
    if [[ -n "$local_pin" && -n "$local_installed" && "$local_pin" != "$local_installed" ]]; then
        echo
        echo "jj version drift: installed=$local_installed, pinned=$local_pin"
        echo "run: bash $ME_PREFIX/repo/setup.sh --force-rebuild=jj"
    fi
fi

echo
info "done. Restart your shell for pulled changes to take effect."
