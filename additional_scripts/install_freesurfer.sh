#!/usr/bin/env bash
# install_freesurfer.sh --- install FreeSurfer under $ME_PREFIX/opt/freesurfer.
#
# FreeSurfer ships prebuilt RHEL-family tarballs from
# https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/
#
# You'll need a separately-obtained license file (register at
# https://surfer.nmr.mgh.harvard.edu/registration.html).
#
# Usage:
#   bash install_freesurfer.sh [--version=7.5.0] [--license=/path/to/license.txt]

set -euo pipefail

ME_PREFIX="${ME_PREFIX:-$HOME/.melocal}"
VERSION=7.5.0           # bump here when upstream releases a new point version
LICENSE=""

for arg in "$@"; do
    case "$arg" in
        --version=*) VERSION=${arg#*=} ;;
        --license=*) LICENSE=${arg#*=} ;;
        -h|--help)
            sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "unknown flag: $arg" >&2; exit 2 ;;
    esac
done

DEST="$ME_PREFIX/opt/freesurfer"
BUILD="${TMPDIR:-$HOME}/freesurfer-install-$$"
TARBALL="freesurfer-linux-centos8_x86_64-${VERSION}.tar.gz"
URL="https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${VERSION}/${TARBALL}"

mkdir -p "$BUILD"
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"

echo "Fetching $URL"
curl -fsSLO "$URL"

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
tar -xzf "$TARBALL" --strip-components=1 -C "$(dirname "$DEST")"
# Older FreeSurfer tarballs extract into 'freesurfer/'; strip-components=1 flattens
# that into the parent so we can rename if needed. If extraction put files at the
# parent root by accident, bail.
[[ -x "$DEST/SetUpFreeSurfer.sh" ]] || {
    echo "error: SetUpFreeSurfer.sh not found at $DEST; extraction layout changed?" >&2
    exit 1
}

if [[ -n "$LICENSE" && -f "$LICENSE" ]]; then
    cp "$LICENSE" "$DEST/license.txt"
    echo "License installed at $DEST/license.txt"
else
    echo "Reminder: place your license at $DEST/license.txt before using."
fi

cat <<EOF

FreeSurfer $VERSION installed at $DEST.

Add to your shell config (or a job script):
  export FREESURFER_HOME="$DEST"
  export SUBJECTS_DIR="\$FREESURFER_HOME/subjects"
  export FS_LICENSE="$DEST/license.txt"
  source "\$FREESURFER_HOME/SetUpFreeSurfer.sh"
EOF
