#!/usr/bin/env bash
# Build a .deb from the Flutter Linux release bundle.
#
# Usage: packaging/deb/build_deb.sh [version]
# Requires: flutter build linux --release (run first), dpkg-deb.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
PKG_NAME="rafiq"
AUMID="com.ideas2d.themuslimscompanion"
VERSION="${1:-1.0.0}"
ARCH="amd64"
MAINTAINER="ideas2d <ideas2d@users.noreply.github.com>"

if [ ! -x "$BUNDLE/the_muslims_companion" ]; then
  echo "error: release bundle not found — run: flutter build linux --release" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Layout: /usr/lib/rafiq/<bundle>, /usr/bin/rafiq wrapper, desktop/icon/metainfo.
install -Dm755 "$BUNDLE/the_muslims_companion" "$STAGE/usr/lib/rafiq/the_muslims_companion"
cp -a "$BUNDLE/lib" "$STAGE/usr/lib/rafiq/lib"
cp -a "$BUNDLE/data" "$STAGE/usr/lib/rafiq/data"

install -Dm755 "$ROOT/packaging/deb/rafiq" "$STAGE/usr/bin/rafiq"
install -Dm644 "$ROOT/packaging/deb/$AUMID.desktop" \
  "$STAGE/usr/share/applications/$AUMID.desktop"
install -Dm644 "$ROOT/packaging/deb/$AUMID.metainfo.xml" \
  "$STAGE/usr/share/metainfo/$AUMID.metainfo.xml"

# Icons from the Android mipmap set (mdpi=48, xxxhdpi=192).
install -Dm644 "$ROOT/android/app/src/main/res/mipmap-mdpi/ic_launcher.png" \
  "$STAGE/usr/share/icons/hicolor/48x48/apps/$AUMID.png"
install -Dm644 "$ROOT/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" \
  "$STAGE/usr/share/icons/hicolor/192x192/apps/$AUMID.png"

# DEBIAN/control
mkdir -p "$STAGE/DEBIAN"
SIZE_KB="$(du -sk "$STAGE/usr" | cut -f1)"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Installed-Size: $SIZE_KB
Maintainer: $MAINTAINER
Depends: libgtk-3-0, libblkid1, liblzma5
Homepage: https://github.com/ideas2d/TheMuslimsCompanion
Description: Muslim companion — morning/evening adhkar, prayer counter, favorites
 Rafiq (رفيق المسلم) is an offline Muslim companion app. It provides
 morning and evening adhkar from bundled sources, a prayer counter
 (tasbih), favorites, and search — all in Arabic. Fully offline:
 no account, no analytics, no ads.
EOF

OUT="$ROOT/build/rafiq_${VERSION}_${ARCH}.deb"
mkdir -p "$(dirname "$OUT")"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT"
echo "Built $OUT"
