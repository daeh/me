# scripts/lib.sh --- shared declarations and install functions.
# Sourced by setup.sh and every scripts/install_*.sh wrapper.
#
# Safe to source repeatedly: everything here is either a `declare` or a
# function definition; no side effects at the top level.
#
# Callers (setup.sh, scripts/*.sh) are responsible for `set -euo pipefail`,
# `umask`, and any final cleanup.

# ============================================================================
# Version pins (verified via live upstream lookups 2026-04-21).
# When bumping a version, run once with --verify-hashes=0 to print the new
# sha256 and paste it into the table below.
# ============================================================================

LIBEVENT_VERSION=2.1.12-stable            # https://libevent.org/
NCURSES_VERSION=6.6                       # https://invisible-island.net/ncurses/
OPENSSL_VERSION=3.6.2                     # https://openssl-library.org/source/
CURL_VERSION=8.19.0                       # https://curl.se/download.html
ZSH_VERSION=5.9                           # https://zsh.sourceforge.io/
TMUX_VERSION=3.6a                         # https://github.com/tmux/tmux/releases
VIM_VERSION=9.2.0387                      # https://github.com/vim/vim/tags
GIT_VERSION=2.54.0                        # https://git-scm.com/
GIT_MIN_VERSION=2.54
JJ_VERSION=0.40.0                         # https://github.com/jj-vcs/jj/releases
TASK_VERSION=3.50.0                       # https://github.com/go-task/task/releases
HELIX_VERSION=25.07.1                     # https://github.com/helix-editor/helix/releases
PYTHON_VERSION=3.14                       # uv resolves patch; falls back to 3.13

# Optional SHA256 verification table. Leave a cell empty to skip that file.
# Populate after first successful install (the script prints each hash).
declare -A SHA256=(
    [libevent]=""
    [ncurses]=""
    [openssl]=""
    [curl]=""
    [zsh]=""
    [tmux]=""
    [vim]=""
    [git]=""
    [jj]=""
    [task]=""
    [helix]=""
)

# ============================================================================
# Flag defaults (can be overridden via parse_flags "$@" or by the environment)
# ============================================================================

ME_PREFIX="${ME_PREFIX:-$HOME/.melocal}"
BUILD_DIR="${BUILD_DIR:-}"
OFFLINE="${OFFLINE:-0}"
VERIFY_HASHES="${VERIFY_HASHES:-0}"
SKIP_DEPS="${SKIP_DEPS:-0}"
SKIP_TOOLS="${SKIP_TOOLS:-0}"
SKIP_LANGS="${SKIP_LANGS:-0}"
SKIP_SHELL="${SKIP_SHELL:-0}"
FORCE_REBUILD="${FORCE_REBUILD:-}"
FORCE_REBUILD_ALL="${FORCE_REBUILD_ALL:-0}"
PREFLIGHT_DONE="${PREFLIGHT_DONE:-0}"

# ============================================================================
# Colors + logging
# ============================================================================

if [[ -t 1 ]]; then
    _c_reset=$'\033[0m'
    _c_red=$'\033[1;31m'
    _c_green=$'\033[1;32m'
    _c_yellow=$'\033[1;33m'
    _c_blue=$'\033[1;34m'
else
    _c_reset=''; _c_red=''; _c_green=''; _c_yellow=''; _c_blue=''
fi

info()  { printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*" >&2; }
step()  { printf '\n%s==> %s%s\n' "$_c_green" "$*" "$_c_reset" >&2; }
warn()  { printf '%swarn:%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
die()   { printf '%serror:%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; exit 1; }

# ============================================================================
# Flag parsing
# ============================================================================

parse_flags() {
    while (( $# )); do
        case $1 in
            --prefix=*)          ME_PREFIX=${1#*=} ;;
            --src=*)             BUILD_DIR=${1#*=} ;;
            --offline)           OFFLINE=1 ;;
            --verify-hashes)     VERIFY_HASHES=1 ;;
            --skip-deps)         SKIP_DEPS=1 ;;
            --skip-tools)        SKIP_TOOLS=1 ;;
            --skip-langs)        SKIP_LANGS=1 ;;
            --skip-shell)        SKIP_SHELL=1 ;;
            --force-rebuild)     FORCE_REBUILD_ALL=1 ;;
            --force-rebuild=*)   FORCE_REBUILD=${1#*=} ;;
            -h|--help)
                cat >&2 <<'EOH'
Usage: setup.sh [--prefix=DIR] [--src=DIR] [--offline] [--verify-hashes]
                [--skip-deps] [--skip-tools] [--skip-langs] [--skip-shell]
                [--force-rebuild[=PKG]]

Or run a single phase:
  bash scripts/preflight.sh
  bash scripts/install_deps.sh
  bash scripts/install_tools.sh
  bash scripts/install_langs.sh
  bash scripts/install_shell.sh
  bash scripts/finalize.sh

Phase scripts take the same flags; defaults agree with setup.sh.
EOH
                exit 0
                ;;
            *) die "unknown flag: $1" ;;
        esac
        shift
    done
    export ME_PREFIX
}

# ============================================================================
# Generic helpers
# ============================================================================

# version_gt A B --- succeed if A > B as dotted version.
version_gt() {
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" && "$1" != "$2" ]]
}

version_ge() {
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

# Print "$1" sha256 to stderr; if a nonempty hash is registered in $SHA256 and
# $VERIFY_HASHES=1, abort on mismatch.
verify_sha256() {
    local file=$1 key=$2 expected actual
    expected=${SHA256[$key]:-}
    actual=$(sha256sum "$file" | awk '{print $1}')
    info "sha256($key) = $actual"
    if [[ -n "$expected" && "$VERIFY_HASHES" == 1 ]]; then
        if [[ "$expected" != "$actual" ]]; then
            die "sha256 mismatch for $key ($file): expected $expected, got $actual"
        fi
        info "sha256 OK: $key"
    elif [[ -z "$expected" && "$VERIFY_HASHES" == 1 ]]; then
        die "--verify-hashes set but no SHA256 registered for '$key' (paste the value above into the SHA256 table)"
    fi
}

# Fetch a URL to a local file if missing. Fails loud on 404.
fetch() {
    local url=$1 dest=$2
    if [[ -s "$dest" ]]; then
        info "cached: $(basename "$dest")"
        return 0
    fi
    [[ "$OFFLINE" == 1 ]] && die "offline mode: missing cached file $dest"
    info "fetching $url"
    curl --fail --location --show-error --silent -o "$dest.part" "$url" \
        || die "download failed: $url"
    mv "$dest.part" "$dest"
}

# Extract a tarball into the build dir.
extract() {
    local archive=$1 dest=$2
    mkdir -p "$dest"
    case "$archive" in
        *.tar.xz|*.txz)  tar --extract --file="$archive" --directory="$dest" --strip-components=1 --xz ;;
        *.tar.gz|*.tgz)  tar --extract --file="$archive" --directory="$dest" --strip-components=1 --gzip ;;
        *.tar.bz2)       tar --extract --file="$archive" --directory="$dest" --strip-components=1 --bzip2 ;;
        *) die "unknown archive format: $archive" ;;
    esac
}

# Per-package sentinel. Use a simple "binary exists" check for tools, and a
# dotfile sentinel for deps. Honors --force-rebuild.
needs_rebuild() {
    local key=$1 sentinel=$2
    [[ "$FORCE_REBUILD_ALL" == 1 ]] && return 0
    [[ "$FORCE_REBUILD" == "$key" ]] && return 0
    [[ ! -e "$sentinel" ]] && return 0
    return 1
}

clear_force_for() {
    local key=$1 sentinel=$2 opt_dir=${3:-}
    if [[ "$FORCE_REBUILD" == "$key" ]]; then
        rm -rf "$sentinel" "$opt_dir"
    fi
}

# ============================================================================
# Pre-flight
# ============================================================================

preflight_os() {
    step "Pre-flight: OS check"
    [[ -r /etc/os-release ]] || die "no /etc/os-release"
    . /etc/os-release
    [[ "$ID" == "rocky" ]] || die "only Rocky Linux is supported (got ID=$ID)"
    version_ge "$VERSION_ID" 8.10 || die "Rocky $VERSION_ID < 8.10"
    info "Rocky Linux $VERSION_ID"
}

preflight_lmod() {
    step "Pre-flight: Lmod"
    local init
    for init in \
        /etc/profile.d/z00_lmod.sh \
        /etc/profile.d/lmod.sh \
        /usr/share/lmod/lmod/init/bash
    do
        if [[ -f "$init" ]]; then
            # Some Lmod init files contain zsh-flavored `autoload` calls that
            # bash reports as "autoload: command not found". Harmless — filter.
            # shellcheck source=/dev/null
            { . "$init" || true; } 2> >(grep -v 'autoload: command not found' >&2)
            info "sourced $init"
            break
        fi
    done

    if command -v module >/dev/null 2>&1; then
        # StdEnv provides gcc/12.2.0 on ORCD; load it explicitly in case
        # we're running in a stripped sbatch environment.
        module load StdEnv 2>/dev/null || true
    else
        warn "no 'module' command; relying on system PATH"
    fi
}

preflight_toolchain() {
    step "Pre-flight: toolchain"
    command -v gcc  >/dev/null 2>&1 || die "gcc not found after StdEnv load"
    command -v make >/dev/null 2>&1 || die "make not found"
    command -v curl >/dev/null 2>&1 || die "curl not found (needed to bootstrap)"

    local gccver
    gccver=$(gcc -dumpfullversion 2>/dev/null || gcc -dumpversion)
    info "gcc $gccver"
    version_ge "$gccver" 8.0 || die "gcc $gccver < 8.0; load a newer StdEnv"

    # cmake is not strictly needed but some optional tools want ≥ 3.20.
    if ! command -v cmake >/dev/null 2>&1 || ! version_ge "$(cmake --version | awk 'NR==1{print $3}')" 3.20; then
        if command -v module >/dev/null 2>&1; then
            module load cmake 2>/dev/null || warn "could not load cmake module; continuing"
        fi
    fi
}

preflight_network() {
    [[ "$OFFLINE" == 1 ]] && { info "offline: skipping network preflight"; return 0; }
    step "Pre-flight: network reachability"
    local hosts=(
        github.com
        ftp.gnu.org
        curl.se
        sourceforge.net
        libevent.org
        astral.sh
        fnm.vercel.app
        bun.sh
        nodejs.org
        invisible-island.net
        www.kernel.org
    )
    local host failures=()
    for host in "${hosts[@]}"; do
        if curl --silent --fail --head --max-time 10 "https://${host}/" >/dev/null; then
            printf '  %s✓%s %s\n' "$_c_green" "$_c_reset" "$host" >&2
        else
            printf '  %s✗%s %s\n' "$_c_red" "$_c_reset" "$host" >&2
            failures+=("$host")
        fi
    done
    if (( ${#failures[@]} )); then
        warn "continuing despite unreachable hosts; specific downloads will fail loud if blocked"
    else
        info "all ${#hosts[@]} hosts reachable"
    fi
}

run_preflight() {
    preflight_os
    preflight_lmod
    preflight_toolchain
    preflight_network
    PREFLIGHT_DONE=1
}

# If preflight hasn't already run in this shell, run it now. Called by phase
# scripts when they're invoked standalone.
ensure_preflight() {
    [[ "$PREFLIGHT_DONE" == 1 ]] && return 0
    run_preflight
}

# ============================================================================
# Build dir
# ============================================================================

pick_build_dir() {
    if [[ -n "$BUILD_DIR" ]]; then
        :
    elif [[ -n "${TMPDIR:-}" && -w "$TMPDIR" ]]; then
        BUILD_DIR="$TMPDIR/me-build"
    else
        BUILD_DIR="$ME_PREFIX/src"
    fi
    mkdir -p "$BUILD_DIR"
    info "build dir: $BUILD_DIR"
}

cleanup_build_on_success() {
    # Keep $BUILD_DIR on failure for inspection; on success, clean it unless
    # it lives under $ME_PREFIX (in which case the user can re-run with cached
    # tarballs if they want).
    if [[ "$BUILD_DIR" != "$ME_PREFIX"* ]]; then
        rm -rf "$BUILD_DIR"
    fi
}

# ============================================================================
# Dep builds (static libs or isolated shared prefixes)
# ============================================================================

install_libevent() {
    local key=libevent
    local opt="$ME_PREFIX/opt/libevent"
    local sentinel="$opt/.installed"
    clear_force_for "$key" "$sentinel" "$opt"
    needs_rebuild "$key" "$sentinel" || { info "libevent: already installed"; return 0; }
    step "Build: libevent $LIBEVENT_VERSION"

    local url="https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz"
    local tar="$BUILD_DIR/libevent-${LIBEVENT_VERSION}.tar.gz"
    local src="$BUILD_DIR/libevent-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    (
        cd "$src"
        ./configure --prefix="$opt" --disable-shared --disable-openssl
        make -j"$(nproc)"
        make install
    )
    touch "$sentinel"
}

install_ncurses() {
    local key=ncurses
    local opt="$ME_PREFIX/opt/ncurses"
    local sentinel="$opt/.installed"
    clear_force_for "$key" "$sentinel" "$opt"
    needs_rebuild "$key" "$sentinel" || { info "ncurses: already installed"; return 0; }
    step "Build: ncurses $NCURSES_VERSION"

    local url="https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
    local tar="$BUILD_DIR/ncurses-${NCURSES_VERSION}.tar.gz"
    local src="$BUILD_DIR/ncurses-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    (
        cd "$src"
        ./configure --prefix="$opt" \
            --enable-widec --with-shared --enable-rpath \
            --without-debug --without-ada \
            CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j"$(nproc)"
        make install
    )
    ensure_ncurses_aliases
    touch "$sentinel"
}

install_openssl() {
    local key=openssl
    local opt="$ME_PREFIX/opt/openssl"
    local sentinel="$opt/.installed"
    clear_force_for "$key" "$sentinel" "$opt"
    needs_rebuild "$key" "$sentinel" || { info "openssl: already installed"; return 0; }
    step "Build: openssl $OPENSSL_VERSION"

    local url="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"
    local tar="$BUILD_DIR/openssl-${OPENSSL_VERSION}.tar.gz"
    local src="$BUILD_DIR/openssl-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    (
        cd "$src"
        ./config --prefix="$opt" --openssldir="$opt/ssl" shared \
            -Wl,-rpath,"$opt/lib" -Wl,-rpath,"$opt/lib64"
        make -j"$(nproc)"
        make install_sw install_ssldirs
    )
    touch "$sentinel"
}

install_curl() {
    local key=curl
    local opt="$ME_PREFIX/opt/curl"
    local sentinel="$opt/.installed"
    clear_force_for "$key" "$sentinel" "$opt"
    needs_rebuild "$key" "$sentinel" || { info "curl: already installed"; return 0; }
    step "Build: curl $CURL_VERSION"

    local url="https://curl.se/download/curl-${CURL_VERSION}.tar.gz"
    local tar="$BUILD_DIR/curl-${CURL_VERSION}.tar.gz"
    local src="$BUILD_DIR/curl-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    local ssl="$ME_PREFIX/opt/openssl"
    local ssl_lib="$ssl/lib64"
    [[ -d "$ssl_lib" ]] || ssl_lib="$ssl/lib"
    (
        cd "$src"
        # --without-libpsl: curl 8.x now errors when libpsl-devel is absent
        # rather than silently disabling. Rocky 8 minimal doesn't ship it and
        # we lack sudo. psl is only used for cookie-domain validation — git
        # doesn't need it.
        ./configure --prefix="$opt" \
            --with-openssl="$ssl" \
            --enable-shared \
            --without-libpsl \
            LDFLAGS="-Wl,-rpath,$opt/lib -Wl,-rpath,$ssl_lib -L$ssl_lib"
        make -j"$(nproc)"
        make install
    )
    touch "$sentinel"
}

# Shared flag builder for consumers linking against $ME_PREFIX/opt/<dep>.
ncurses_flags() {
    local n="$ME_PREFIX/opt/ncurses"
    printf -- '-I%s/include -I%s/include/ncursesw' "$n" "$n"
}
ncurses_ldflags() {
    local n="$ME_PREFIX/opt/ncurses"
    printf -- '-Wl,-rpath,%s/lib -L%s/lib' "$n" "$n"
}

# --enable-widec builds libncursesw but not libncurses. Consumers like tmux
# add -lncurses to the link line anyway; Rocky 8 without ncurses-devel is
# also missing the system's libncurses.so symlink, so ld fails to resolve
# -lncurses anywhere. Alias the widec libs under their non-widec names in
# our prefix. Idempotent; safe to call before any consumer build.
ensure_ncurses_aliases() {
    local opt="$ME_PREFIX/opt/ncurses" lib
    [[ -d "$opt/lib" ]] || return 0
    for lib in ncurses tinfo form menu panel; do
        if [[ -f "$opt/lib/lib${lib}w.so" && ! -e "$opt/lib/lib${lib}.so" ]]; then
            ln -s "lib${lib}w.so" "$opt/lib/lib${lib}.so"
        fi
    done
}

# Self-sufficient phase runners: safe to call directly after `source lib.sh`
# without any prep. `ensure_preflight` / `pick_build_dir` / the `mkdir` are
# all idempotent so repeated calls across phases are free.

_phase_prep() {
    ensure_preflight
    mkdir -p "$ME_PREFIX/bin" "$ME_PREFIX/opt"
    pick_build_dir
}

run_install_deps() {
    _phase_prep
    install_libevent
    install_ncurses
    install_openssl
    install_curl
}

# ============================================================================
# Tool builds (source) + prebuilt binaries
# ============================================================================

install_zsh() {
    local key=zsh
    local sentinel="$ME_PREFIX/bin/zsh"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"
    needs_rebuild "$key" "$sentinel" || { info "zsh: already installed"; return 0; }
    step "Build: zsh $ZSH_VERSION"
    ensure_ncurses_aliases

    local url="https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download"
    local tar="$BUILD_DIR/zsh-${ZSH_VERSION}.tar.xz"
    local src="$BUILD_DIR/zsh-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    (
        cd "$src"
        CPPFLAGS="$(ncurses_flags)" \
        LDFLAGS="$(ncurses_ldflags)" \
            ./configure --prefix="$ME_PREFIX" \
                --enable-multibyte \
                --with-tcsetpgrp
        make -j"$(nproc)"
        make install
    )
}

install_tmux() {
    local key=tmux
    local sentinel="$ME_PREFIX/bin/tmux"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"
    needs_rebuild "$key" "$sentinel" || { info "tmux: already installed"; return 0; }
    step "Build: tmux $TMUX_VERSION"
    ensure_ncurses_aliases

    local url="https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    local tar="$BUILD_DIR/tmux-${TMUX_VERSION}.tar.gz"
    local src="$BUILD_DIR/tmux-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"

    # Three-part workaround for tmux 3.6a on Rocky 8 + glibc 2.28+:
    #
    # 1. compat.h declares forkpty() with a non-const signature, unconditional
    #    on HAVE_FORKPTY, which conflicts with glibc's const-qualified <pty.h>
    #    prototype. Patch the declaration to add the const qualifiers.
    if grep -q 'forkpty(int \*, char \*, struct termios \*, struct winsize \*)' "$src/compat.h"; then
        info "patching compat.h forkpty() prototype to match glibc"
        sed -i \
            's|forkpty(int \*, char \*, struct termios \*, struct winsize \*)|forkpty(int *, char *, const struct termios *, const struct winsize *)|' \
            "$src/compat.h"
    fi

    # 2. Configure uses AC_LINK_IFELSE (no cache var) to probe forkpty; on this
    #    host it decides forkpty is missing, then the Makefile references
    #    compat/forkpty-linux.c which 3.6a doesn't ship (Linux is assumed to
    #    have forkpty in libutil). Stub it out: linker will resolve forkpty
    #    from -lutil, so the empty object contributes nothing.
    if [[ ! -e "$src/compat/forkpty-linux.c" ]]; then
        info "stubbing compat/forkpty-linux.c (tmux 3.6a doesn't ship this)"
        mkdir -p "$src/compat"
        printf '/* Linux: forkpty is provided by libutil. */\n' \
            > "$src/compat/forkpty-linux.c"
    fi

    # 3. glibc's resolv.h defines b64_ntop/b64_pton as macros expanding to
    #    __b64_ntop/__b64_pton. compat/base64.c picks up the macro (via a
    #    transitive include) and emits the underscored symbols, but input.c /
    #    tty.c / tty-keys.c call the un-underscored name and fail to link.
    #    Force configure to NOT detect the system b64_ntop via its cache vars
    #    so tmux uses its own compat implementation consistently.
    local le="$ME_PREFIX/opt/libevent"
    # LIBS="-lutil" lets the final link resolve forkpty against libutil, which
    # is what any real forkpty call in tmux will actually use (the stubbed
    # compat shim contributes no symbols).
    (
        cd "$src"
        ac_cv_func_b64_ntop=no \
        ac_cv_search_b64_ntop=no \
        CPPFLAGS="-I$le/include $(ncurses_flags)" \
        LDFLAGS="-L$le/lib $(ncurses_ldflags)" \
        LIBS="-lutil" \
            ./configure --prefix="$ME_PREFIX"
        make -j"$(nproc)"
        make install
    )
}

install_vim() {
    local key=vim
    local sentinel="$ME_PREFIX/bin/vim"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"
    needs_rebuild "$key" "$sentinel" || { info "vim: already installed"; return 0; }
    step "Build: vim $VIM_VERSION"

    local url="https://github.com/vim/vim/archive/refs/tags/v${VIM_VERSION}.tar.gz"
    local tar="$BUILD_DIR/vim-${VIM_VERSION}.tar.gz"
    local src="$BUILD_DIR/vim-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    (
        cd "$src"
        CPPFLAGS="$(ncurses_flags)" \
        LDFLAGS="$(ncurses_ldflags)" \
            ./configure --prefix="$ME_PREFIX" \
                --with-features=huge \
                --enable-multibyte \
                --disable-gui \
                --without-x \
                --disable-nls
        make -j"$(nproc)"
        make install
    )
}

install_git() {
    local key=git
    local sentinel="$ME_PREFIX/bin/git"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"

    # Skip if system git is already new enough. On ORCD it won't be, but this
    # is a safety net for future Rocky versions or local dev machines.
    if [[ ! -e "$sentinel" ]] && command -v git >/dev/null 2>&1; then
        local sysver
        sysver=$(git --version | awk '{print $3}')
        if version_ge "$sysver" "$GIT_MIN_VERSION"; then
            info "git: system git $sysver ≥ $GIT_MIN_VERSION; skipping build"
            return 0
        fi
    fi
    needs_rebuild "$key" "$sentinel" || { info "git: already installed"; return 0; }
    step "Build: git $GIT_VERSION"

    local url="https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz"
    local tar="$BUILD_DIR/git-${GIT_VERSION}.tar.xz"
    local src="$BUILD_DIR/git-src"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$src"
    extract "$tar" "$src"
    local c="$ME_PREFIX/opt/curl"
    local ssl="$ME_PREFIX/opt/openssl"
    local ssl_lib="$ssl/lib64"
    [[ -d "$ssl_lib" ]] || ssl_lib="$ssl/lib"
    (
        cd "$src"
        make prefix="$ME_PREFIX" \
            CURLDIR="$c" OPENSSLDIR="$ssl" \
            LDFLAGS="-Wl,-rpath,$c/lib -Wl,-rpath,$ssl_lib -L$c/lib -L$ssl_lib" \
            NO_GETTEXT=1 NO_PERL=1 \
            -j"$(nproc)" all
        make prefix="$ME_PREFIX" NO_GETTEXT=1 NO_PERL=1 install
    )
}

install_jj() {
    local key=jj
    local sentinel="$ME_PREFIX/bin/jj"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"
    needs_rebuild "$key" "$sentinel" || { info "jj: already installed"; return 0; }
    step "Install: jj $JJ_VERSION (prebuilt musl binary)"

    local url="https://github.com/jj-vcs/jj/releases/download/v${JJ_VERSION}/jj-v${JJ_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    local tar="$BUILD_DIR/jj-${JJ_VERSION}.tar.gz"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    mkdir -p "$ME_PREFIX/bin"
    tar --extract --file="$tar" --directory="$ME_PREFIX/bin" --gzip jj
    chmod +x "$ME_PREFIX/bin/jj"
}

install_task() {
    local key=task
    local sentinel="$ME_PREFIX/bin/task"
    [[ "$FORCE_REBUILD" == "$key" ]] && rm -f "$sentinel"
    needs_rebuild "$key" "$sentinel" || { info "task: already installed"; return 0; }
    step "Install: task $TASK_VERSION (Taskfile runner)"

    local url="https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_amd64.tar.gz"
    local tar="$BUILD_DIR/task-${TASK_VERSION}.tar.gz"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    mkdir -p "$ME_PREFIX/bin"
    tar --extract --file="$tar" --directory="$ME_PREFIX/bin" --gzip task
    chmod +x "$ME_PREFIX/bin/task"
}

install_helix() {
    local key=helix
    local opt="$ME_PREFIX/opt/helix"
    local sentinel="$ME_PREFIX/bin/hx"
    if [[ "$FORCE_REBUILD" == "$key" ]]; then
        rm -rf "$opt" "$sentinel"
    fi
    needs_rebuild "$key" "$sentinel" || { info "helix: already installed"; return 0; }
    step "Install: helix $HELIX_VERSION"

    local url="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz"
    local tar="$BUILD_DIR/helix-${HELIX_VERSION}.tar.xz"

    fetch "$url" "$tar"
    verify_sha256 "$tar" "$key"
    rm -rf "$opt"
    mkdir -p "$opt"
    tar --extract --file="$tar" --directory="$opt" --strip-components=1 --xz
    [[ -x "$opt/hx" ]] || die "helix tarball layout changed; hx not at expected path"
    ln -sfn "$opt/hx" "$sentinel"
}

run_install_tools() {
    _phase_prep
    install_zsh
    install_tmux
    install_vim
    install_git
    install_jj
    install_task
    install_helix
}

# ============================================================================
# Language runtimes
# ============================================================================

install_uv() {
    local sentinel="$ME_PREFIX/bin/uv"
    [[ "$FORCE_REBUILD" == "uv" ]] && rm -f "$sentinel"
    needs_rebuild "uv" "$sentinel" || { info "uv: already installed"; return 0; }
    step "Install: uv (official installer)"

    mkdir -p "$ME_PREFIX/bin"
    UV_INSTALL_DIR="$ME_PREFIX/bin" INSTALLER_NO_MODIFY_PATH=1 \
        curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_fnm() {
    local sentinel="$ME_PREFIX/bin/fnm"
    [[ "$FORCE_REBUILD" == "fnm" ]] && rm -f "$sentinel"
    needs_rebuild "fnm" "$sentinel" || { info "fnm: already installed"; return 0; }
    step "Install: fnm (official installer)"

    mkdir -p "$ME_PREFIX/bin"
    curl -fsSL https://fnm.vercel.app/install | bash -s -- \
        --install-dir "$ME_PREFIX/bin" --skip-shell
}

install_node_yarn() {
    local node_sentinel="$ME_PREFIX/fnm/aliases/default"
    [[ "$FORCE_REBUILD" == "node" ]] && rm -rf "$ME_PREFIX/fnm"
    if [[ -e "$node_sentinel" && "$FORCE_REBUILD_ALL" != 1 ]]; then
        info "node: already installed via fnm"
    else
        step "Install: Node LTS + yarn (via fnm + corepack)"
        mkdir -p "$ME_PREFIX/fnm"
        FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" install --lts
        # Set the default to whatever fnm just activated so new shells pick it up.
        local active
        active=$(FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" current 2>/dev/null || true)
        if [[ -n "$active" && "$active" != "system" ]]; then
            FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" default "$active"
        fi
    fi

    # Corepack ships with node. Activate fnm's environment in this shell and
    # install yarn globally via corepack (single source of truth for yarn).
    eval "$(FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" env --corepack-enabled --shell bash)"
    if ! command -v yarn >/dev/null 2>&1; then
        info "installing yarn via corepack"
        # `corepack install -g` is the modern recipe (Corepack ≥ 0.30).
        # On older corepack, fall back to `corepack prepare ... --activate`.
        corepack install -g yarn@stable 2>/dev/null \
            || corepack prepare yarn@stable --activate
    fi
}

install_bun() {
    local sentinel="$ME_PREFIX/bun/bin/bun"
    [[ "$FORCE_REBUILD" == "bun" ]] && rm -rf "$ME_PREFIX/bun"
    needs_rebuild "bun" "$sentinel" || { info "bun: already installed"; return 0; }
    step "Install: bun (official installer)"
    # Note: Rocky 8.10 kernel is 4.18.x; bun recommends ≥ 5.6 but gracefully
    # degrades on ≥ 3.10 (per bun.sh/docs/installation). Usable.
    mkdir -p "$ME_PREFIX/bun"
    curl -fsSL https://bun.sh/install | \
        BUN_INSTALL="$ME_PREFIX/bun" \
        BUN_INSTALL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bun" \
        bash \
        || warn "bun install failed; continuing"
}

install_python_default() {
    local venv="$ME_PREFIX/python-default"
    local sentinel="$venv/bin/python"
    [[ "$FORCE_REBUILD" == "python" ]] && rm -rf "$venv"
    needs_rebuild "python" "$sentinel" || { info "python-default: already seeded"; return 0; }
    step "Install: default Python venv ($PYTHON_VERSION via uv)"

    # uv python install is idempotent.
    if ! "$ME_PREFIX/bin/uv" python install "$PYTHON_VERSION" 2>&1; then
        warn "could not resolve python $PYTHON_VERSION; falling back to 3.13"
        "$ME_PREFIX/bin/uv" python install 3.13
        PYTHON_VERSION=3.13
    fi
    "$ME_PREFIX/bin/uv" venv --python "$PYTHON_VERSION" --seed "$venv"
}

install_rmate() {
    local sentinel="$ME_PREFIX/bin/rmate"
    [[ "$FORCE_REBUILD" == "rmate" ]] && rm -f "$sentinel"
    needs_rebuild "rmate" "$sentinel" || { info "rmate: already installed"; return 0; }
    step "Install: rmate"
    mkdir -p "$ME_PREFIX/bin"
    curl -fsSLo "$sentinel" \
        https://raw.githubusercontent.com/textmate/rmate/master/bin/rmate
    chmod +x "$sentinel"
}

run_install_langs() {
    _phase_prep
    install_uv
    install_fnm
    install_node_yarn
    install_bun
    install_python_default
    install_rmate
}

# ============================================================================
# Shell env: repo + prezto + p10k + tpm + dotfile symlinks
# ============================================================================

clone_or_update_repo() {
    local repo="$ME_PREFIX/repo"
    step "Dotfiles repo"
    if [[ -d "$repo/.git" || -L "$repo" ]]; then
        if [[ -d "$repo/.git" ]]; then
            info "git pull in $repo"
            git -C "$repo" pull --ff-only || warn "repo pull failed (continuing)"
        else
            info "$repo is a symlink; not pulling"
        fi
    else
        # If the user invoked setup.sh from inside a local checkout, link it.
        # Otherwise clone from the canonical URL.
        local here="${REPO_LOCAL_CHECKOUT:-}"
        if [[ -n "$here" && -f "$here/setup.sh" && -d "$here/dotfiles" ]]; then
            info "linking repo from local checkout at $here"
            mkdir -p "$(dirname "$repo")"
            ln -sfn "$here" "$repo"
        else
            info "cloning github.com/daeh/me → $repo"
            git clone https://github.com/daeh/me.git "$repo"
        fi
    fi
}

# dotfile_link <src-in-repo> <dest>. Backup prior non-symlink targets.
# Appends the destination to $ME_PREFIX/manifest.txt for uninstall.
dotfile_link() {
    local src=$1 dest=$2
    local repo="$ME_PREFIX/repo"
    local from="$repo/dotfiles/$src"
    [[ -e "$from" ]] || { warn "missing: $from (skipping)"; return 0; }

    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        local bak
        bak="${dest}.bak.$(date +%F_%H.%M.%S)"
        mv "$dest" "$bak"
        info "backed up $dest → $bak"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$from" "$dest"
    info "linked $dest → $from"
    printf '%s\n' "$dest" >> "$ME_PREFIX/manifest.txt"
}

link_zprezto() {
    local dest="$HOME/.zprezto"
    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        local bak
        bak="${dest}.bak.$(date +%F_%H.%M.%S)"
        mv "$dest" "$bak"
        info "backed up $dest → $bak"
    fi
    ln -s "$ME_PREFIX/zprezto" "$dest"
    printf '%s\n' "$dest" >> "$ME_PREFIX/manifest.txt"
    info "linked $dest → $ME_PREFIX/zprezto"
}

install_dotfiles() {
    step "Dotfile symlinks"

    # Fresh manifest each run; the symlinks we (re)create are re-appended.
    : > "$ME_PREFIX/manifest.txt"

    # --- Special case: pre-existing ~/.gitconfig shadows anything we set. ---
    # We want ~/.gitconfig to be our symlink, so a regular file there needs
    # backing up first.
    if [[ -f "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]]; then
        mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak.$(date +%F_%H.%M.%S)"
    fi

    dotfile_link zshrc          "$HOME/.zshrc"
    dotfile_link zshenv         "$HOME/.zshenv"
    dotfile_link zpreztorc      "$HOME/.zpreztorc"
    dotfile_link p10k.zsh       "$HOME/.p10k.zsh"
    dotfile_link merc           "$HOME/.merc"
    dotfile_link me.conf        "$HOME/.me.conf"
    dotfile_link tmux.conf      "$HOME/.tmux.conf"
    dotfile_link vimrc          "$HOME/.vimrc"
    dotfile_link gitconfig      "$HOME/.gitconfig"
    dotfile_link jjconfig.toml  "$HOME/.jjconfig.toml"
    dotfile_link bashrc         "$HOME/.bashrc"
    dotfile_link bash_profile   "$HOME/.bash_profile"
    dotfile_link screenrc       "$HOME/.screenrc"
    dotfile_link helix/config.toml  "${XDG_CONFIG_HOME:-$HOME/.config}/helix/config.toml"

    link_zprezto
}

install_prezto() {
    local dir="$ME_PREFIX/zprezto"
    step "Prezto"
    if [[ -d "$dir/.git" ]]; then
        info "updating prezto"
        git -C "$dir" pull --ff-only --recurse-submodules || true
        git -C "$dir" submodule update --init --recursive
    else
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "$dir"
    fi
}

install_p10k() {
    local p10k="$ME_PREFIX/powerlevel10k"
    local prompt_dir="$ME_PREFIX/zprezto/modules/prompt/functions"
    step "Powerlevel10k"
    if [[ -d "$p10k/.git" ]]; then
        git -C "$p10k" pull --ff-only || true
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
    fi
    # Expose p10k to prezto's prompt module. This is the documented prezto+p10k
    # integration (see p10k README, section "For Prezto users").
    mkdir -p "$prompt_dir"
    ln -sfn "$p10k/powerlevel10k.zsh-theme" "$prompt_dir/prompt_powerlevel10k_setup"
}

install_tpm() {
    local tpm="$ME_PREFIX/tmux-plugins/tpm"
    step "tmux plugin manager"
    mkdir -p "$ME_PREFIX/tmux-plugins"
    if [[ -d "$tpm/.git" ]]; then
        git -C "$tpm" pull --ff-only || true
    else
        git clone https://github.com/tmux-plugins/tpm.git "$tpm"
    fi

    # Initial plugin install on a PRIVATE socket so user's default-socket
    # tmux sessions are untouched.
    "$ME_PREFIX/bin/tmux" -L me-setup kill-server 2>/dev/null || true
    "$ME_PREFIX/bin/tmux" -L me-setup new-session -d
    TMUX_PLUGIN_MANAGER_PATH="$ME_PREFIX/tmux-plugins/" \
        "$tpm/scripts/install_plugins.sh" || warn "tpm install_plugins had errors"
    "$ME_PREFIX/bin/tmux" -L me-setup kill-server 2>/dev/null || true
}

run_install_shell() {
    _phase_prep
    clone_or_update_repo
    install_prezto
    install_p10k
    install_dotfiles
    install_tpm
}

# ============================================================================
# Finalize: write uninstall.sh, print summary
# ============================================================================

write_uninstaller() {
    step "Write uninstall.sh"
    cat >"$ME_PREFIX/uninstall.sh" <<'EOF'
#!/usr/bin/env bash
# Auto-generated by setup.sh.
# Removes the ~/.<rc> symlinks created by setup.sh, then removes $ME_PREFIX.
# Does NOT touch $XDG_CACHE_HOME (uv, bun, npm, corepack caches).
set -u
ME_PREFIX="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$ME_PREFIX/manifest.txt" ]]; then
    while IFS= read -r link; do
        [[ -z "$link" ]] && continue
        if [[ -L "$link" ]]; then
            rm -v "$link"
        fi
    done < "$ME_PREFIX/manifest.txt"
fi
rm -rfv "$ME_PREFIX"
echo
echo "Uninstalled. Tool caches under \$XDG_CACHE_HOME (uv, bun, corepack, npm)"
echo "are not touched. Remove them manually if desired:"
echo "  rm -rf \${XDG_CACHE_HOME:-\$HOME/.cache}/{uv,bun,node,npm}"
EOF
    chmod +x "$ME_PREFIX/uninstall.sh"
}

print_summary() {
    step "Installed versions"
    printf '  zsh:  %s\n' "$("$ME_PREFIX/bin/zsh" --version 2>/dev/null || echo '?')"
    printf '  tmux: %s\n' "$("$ME_PREFIX/bin/tmux" -V 2>/dev/null || echo '?')"
    printf '  vim:  %s\n' "$("$ME_PREFIX/bin/vim" --version 2>/dev/null | head -1 || echo '?')"
    printf '  git:  %s\n' "$("$ME_PREFIX/bin/git" --version 2>/dev/null || echo '?')"
    printf '  jj:   %s\n' "$("$ME_PREFIX/bin/jj" --version 2>/dev/null || echo '?')"
    printf '  task: %s\n' "$("$ME_PREFIX/bin/task" --version 2>/dev/null || echo '?')"
    printf '  hx:   %s\n' "$("$ME_PREFIX/bin/hx" --version 2>/dev/null | head -1 || echo '?')"
    printf '  uv:   %s\n' "$("$ME_PREFIX/bin/uv" --version 2>/dev/null || echo '?')"
    printf '  fnm:  %s\n' "$("$ME_PREFIX/bin/fnm" --version 2>/dev/null || echo '?')"
    local nodebin
    nodebin=$(FNM_DIR="$ME_PREFIX/fnm" "$ME_PREFIX/bin/fnm" exec which node 2>/dev/null || true)
    if [[ -n "$nodebin" ]]; then
        printf '  node: %s\n' "$("$nodebin" --version)"
    fi
    if [[ -x "$ME_PREFIX/bun/bin/bun" ]]; then
        printf '  bun:  %s\n' "$("$ME_PREFIX/bun/bin/bun" --version 2>/dev/null || echo '?')"
    fi
    if [[ -x "$ME_PREFIX/python-default/bin/python" ]]; then
        printf '  python-default: %s\n' "$("$ME_PREFIX/python-default/bin/python" --version 2>&1 || echo '?')"
    fi

    cat <<EOF

Install complete at $ME_PREFIX.

Next steps:
  - Start a fresh shell:   exec $ME_PREFIX/bin/zsh -l
  - Uninstall:             bash $ME_PREFIX/uninstall.sh
EOF
}

run_finalize() {
    # pick_build_dir so cleanup_build_on_success knows what to remove; harmless
    # if $BUILD_DIR is already set.
    pick_build_dir
    write_uninstaller
    cleanup_build_on_success
    print_summary
}
