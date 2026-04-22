# me

Personal install + dotfiles for MIT ORCD (Rocky Linux 8.10+).

Installs zsh, tmux, vim, git, jujutsu, plus uv / fnm+node / yarn (corepack) /
bun / a default Python venv, and wires up prezto + powerlevel10k. Everything
lands under a single directory (`~/.melocal` by default) so cleanup is a
one-liner.

## Install

```sh
# from your local machine:
scp setup.sh <user>@orcd-login.mit.edu:~/setup.sh

# on ORCD:
bash ~/setup.sh
```

First install takes ~15 min. Re-runs are idempotent (seconds).

Useful flags:

- `--prefix=DIR` — install root (default `$HOME/.melocal`).
- `--force-rebuild` — strip and reinstall everything.
- `--force-rebuild=<pkg>` — rebuild one package (`libevent`, `ncurses`,
  `openssl`, `curl`, `zsh`, `tmux`, `vim`, `git`, `jj`, `uv`, `fnm`, `node`,
  `bun`, `python`, `rmate`). Does not cascade — rebuild dependents yourself.
- `--skip-{deps,tools,langs,shell}` — skip a phase.
- `--offline` — refuse network, use cached tarballs (for re-runs).
- `--verify-hashes` — enforce SHA256 checksums from the table at the top of
  `setup.sh` (populate after a successful first install).

## Update

```sh
bash ~/.melocal/repo/update.sh
```

Git-pulls the dotfile repo, prezto, p10k, TPM. Runs `uv self update`, `fnm
install --lts`, `bun upgrade`. Warns if the pinned `jj` version has drifted.

For the source-built tools (zsh, tmux, vim, git, openssl, curl, ncurses,
libevent): bump the version pin at the top of `setup.sh`, then:

```sh
bash ~/setup.sh --force-rebuild=<pkg>
```

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
| `~/.melocal/bin/` | `zsh`, `tmux`, `vim`, `git`, `jj`, `uv`, `fnm`, `rmate`, `node`-via-fnm shim |
| `~/.melocal/opt/{libevent,ncurses,openssl,curl}/` | Source-built deps, RPATH-linked into consumers |
| `~/.melocal/repo/` | Clone of this repo |
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
| `~/.zprezto` | `~/.melocal/zprezto` |
