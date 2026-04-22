#!/usr/bin/env bash
# install_texlive.sh --- TeX Live on ORCD.
#
# ORCD provides `tex-live/20251104` as an Lmod module. Prefer that unless you
# need a source install (e.g. for a specific scheme or a private texmf tree).
#
# Usage:
#   bash install_texlive.sh                # verify the module is loadable; exit
#   bash install_texlive.sh --full         # source install under $ME_PREFIX/opt/texlive

set -euo pipefail

ME_PREFIX="${ME_PREFIX:-$HOME/.melocal}"
MODE=module

for arg in "$@"; do
    case "$arg" in
        --full)     MODE=source ;;
        -h|--help)
            sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)          echo "unknown flag: $arg" >&2; exit 2 ;;
    esac
done

case "$MODE" in
module)
    for init in \
        /etc/profile.d/z00_lmod.sh \
        /etc/profile.d/lmod.sh \
        /usr/share/lmod/lmod/init/bash
    do
        [[ -f "$init" ]] && { . "$init" || true; break; }
    done
    if ! command -v module >/dev/null 2>&1; then
        echo "error: no Lmod; re-run with --full for source install" >&2
        exit 1
    fi
    module load tex-live 2>/dev/null \
        || { echo "error: tex-live module not loadable; re-run with --full" >&2; exit 1; }
    command -v tlmgr >/dev/null || { echo "error: tlmgr not on PATH after module load" >&2; exit 1; }
    echo "tex-live module loaded: $(tex --version | head -1)"
    echo "Add 'module load tex-live' to job scripts that need TeX."
    ;;
source)
    TEX_ROOT="$ME_PREFIX/opt/texlive"
    TEX_CONFIG="$HOME/texlive-config"
    BUILD="${TMPDIR:-$HOME}/texlive-install-$$"
    mkdir -p "$BUILD"
    trap 'rm -rf "$BUILD"' EXIT
    cd "$BUILD"

    curl -fsSLO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar xf install-tl-unx.tar.gz
    cd install-tl-*

    cat > texlive.profile <<EOL
selected_scheme scheme-full
TEXDIR $TEX_ROOT
TEXMFCONFIG $TEX_CONFIG/.texlive/texmf-config
TEXMFHOME $TEX_CONFIG/texmf
TEXMFLOCAL $TEX_ROOT/texmf-local
TEXMFSYSCONFIG $TEX_ROOT/texmf-config
TEXMFSYSVAR $TEX_ROOT/texmf-var
TEXMFVAR $TEX_CONFIG/.texlive/texmf-var
binary_x86_64-linux 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 1
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 1
EOL

    perl ./install-tl --profile texlive.profile

    echo
    echo "TeX Live installed at $TEX_ROOT"
    echo "Add to your shell config:"
    echo "  export PATH=\"$TEX_ROOT/bin/x86_64-linux:\$PATH\""
    ;;
esac
