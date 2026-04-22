# me

Personal install + dotfiles for MIT ORCD (Rocky Linux 8.10+).

Installs zsh, tmux, vim, git, jujutsu, task, helix, plus uv / fnm+node / yarn
(corepack) / bun / a default Python venv, and wires up prezto + powerlevel10k.
Everything lands under a single directory (`~/.melocal` by default) so cleanup
is one command.

## Install

The repo needs to be on the target machine in full (not just `setup.sh` —
the installer sources `scripts/lib.sh`).

```sh
# on ORCD:
git clone https://github.com/daeh/me.git ~/me
bash ~/me/setup.sh
```

Or, if you don't have HTTPS egress to GitHub from ORCD, copy the tree over from
your local machine:

```sh
# on your local machine:
scp -r /path/to/me <user>@orcd-login.mit.edu:~/me

# on ORCD:
bash ~/me/setup.sh
```

First install takes ~15 min on a login node. Re-runs complete in seconds (every
phase is sentinel-guarded).

Useful flags:

- `--prefix=DIR` — install root (default `$HOME/.melocal`).
- `--force-rebuild` — strip and reinstall everything.
- `--force-rebuild=<pkg>` — rebuild one package (`libevent`, `ncurses`,
  `openssl`, `curl`, `zsh`, `tmux`, `vim`, `git`, `jj`, `task`, `helix`, `uv`,
  `fnm`, `node`, `bun`, `python`, `rmate`). Does not cascade — rebuild
  dependents yourself.
- `--skip-{deps,tools,langs,shell}` — skip a phase.
- `--offline` — refuse network, use cached tarballs (for re-runs).
- `--verify-hashes` — enforce SHA256 checksums from the table at the top of
  `scripts/lib.sh` (populate after a successful first install).

## Structure

```
setup.sh                     orchestrator (75 lines)
scripts/
├── lib.sh                   all declarations + install_*/run_* functions
├── preflight.sh             OS/Lmod/toolchain/network checks
├── install_deps.sh          libevent, ncurses, openssl, curl
├── install_tools.sh         zsh, tmux, vim, git, jj, task, helix
├── install_langs.sh         uv, fnm+node+yarn, bun, python, rmate
├── install_shell.sh         repo clone/link, prezto, p10k, dotfiles, TPM
└── finalize.sh              writes uninstall.sh, prints summary
```

## Running one phase standalone

Each phase wrapper is a self-contained entry point. It sources `lib.sh`,
parses the same flags as `setup.sh`, runs preflight if not yet done, and
executes its phase. Useful for iterating when one step fails or you bumped
a single version pin.

```sh
bash scripts/preflight.sh
bash scripts/install_deps.sh
bash scripts/install_deps.sh --force-rebuild=curl     # one package
bash scripts/install_tools.sh
bash scripts/install_langs.sh
bash scripts/install_shell.sh
bash scripts/finalize.sh
```

## Interactive debugging

Source `lib.sh` once, then call any install function by name:

```sh
source scripts/lib.sh
parse_flags --prefix=$HOME/.melocal    # optional; ME_PREFIX=$HOME/.melocal if no-op
run_preflight                          # or individual preflight_os, preflight_lmod, ...
pick_build_dir
install_ncurses                        # any single install_* function
install_openssl
```

No `set -e` in lib.sh, so an individual function failing won't drop you out of
your shell.

## Update

```sh
bash ~/.melocal/repo/update.sh
```

Git-pulls the dotfile repo, prezto, p10k, TPM. Runs `uv self update`, `fnm
install --lts`, `bun upgrade`. Warns if the pinned `jj` version has drifted.

For the source-built tools (zsh, tmux, vim, git, openssl, curl, ncurses,
libevent): bump the version pin at the top of `scripts/lib.sh`, then:

```sh
bash ~/me/scripts/install_tools.sh --force-rebuild=<pkg>
# or equivalently:
bash ~/me/setup.sh --force-rebuild=<pkg>
```

For prebuilt binaries (`jj`, `task`, `helix`): same recipe — bump the
`*_VERSION` pin in `scripts/lib.sh`, then `--force-rebuild=<pkg>`.

## Uninstall

```sh
bash ~/.melocal/uninstall.sh
```

Removes the `~/.<rc>` symlinks listed in `~/.melocal/manifest.txt`, then
removes `~/.melocal`. Tool caches under `$XDG_CACHE_HOME` (uv, bun, corepack,
npm) are left alone — remove them manually if you want a scorched-earth reset:

```sh
rm -rf ${XDG_CACHE_HOME:-$HOME/.cache}/{uv,bun,node,npm}
```

Strip + reinstall in one line:

```sh
bash ~/.melocal/uninstall.sh && bash ~/me/setup.sh
```

## Optional installs

These live under `additional_scripts/` and are not invoked by `setup.sh`.

- `install_texlive.sh` — verifies the ORCD `tex-live` module is loadable.
  Pass `--full` for a source install under `~/.melocal/opt/texlive`.
- `install_freesurfer.sh` — prebuilt FreeSurfer tarball to
  `~/.melocal/opt/freesurfer`. Pass `--license=/path/to/license.txt` if you
  have one; otherwise supply it afterward.

## What's installed and where

Everything this setup touches lives in one of these locations:

| Path | Contents |
|---|---|
| `~/.melocal/bin/` | `zsh`, `tmux`, `vim`, `git`, `jj`, `task`, `hx`, `uv`, `fnm`, `rmate`, `node`-via-fnm shim |
| `~/.melocal/opt/{libevent,ncurses,openssl,curl}/` | Source-built deps, RPATH-linked into consumers |
| `~/.melocal/opt/helix/` | Helix binary + `runtime/` tree; `HELIX_RUNTIME` points here |
| `~/.melocal/repo/` | Clone (or symlink, if installed from a local checkout) of this repo |
| `~/.melocal/zprezto/` | Prezto + its submodules |
| `~/.melocal/powerlevel10k/` | P10k theme |
| `~/.melocal/fnm/` | `FNM_DIR`; node installs |
| `~/.melocal/bun/` | `BUN_INSTALL` |
| `~/.melocal/python-default/` | uv-seeded default Python venv (on PATH at login) |
| `~/.melocal/tmux-plugins/` | `TMUX_PLUGIN_MANAGER_PATH`; TPM + plugins |
| `~/.melocal/{manifest.txt,uninstall.sh}` | Cleanup machinery |

Dotfiles at `$HOME` are symlinks into `~/.melocal/repo/dotfiles/`:

| `$HOME` symlink | Target |
|---|---|
| `~/.zshrc`, `~/.zshenv`, `~/.zpreztorc`, `~/.p10k.zsh` | `~/.melocal/repo/dotfiles/...` |
| `~/.merc`, `~/.me.conf` | `~/.melocal/repo/dotfiles/...` |
| `~/.tmux.conf`, `~/.vimrc`, `~/.gitconfig`, `~/.jjconfig.toml` | `~/.melocal/repo/dotfiles/...` |
| `~/.bashrc`, `~/.bash_profile`, `~/.screenrc` | `~/.melocal/repo/dotfiles/...` |
| `~/.config/helix/config.toml` | `~/.melocal/repo/dotfiles/helix/config.toml` |
| `~/.zprezto` | `~/.melocal/zprezto` |
