#!/usr/bin/env bash
set -euo pipefail

git fetch --force --tags origin || true
git config --global --add safe.directory "$GITHUB_WORKSPACE"

brew install boost chromaprint cmake fftw gettext glib google-sparsehash \
  gst-libav gst-plugins-bad gst-plugins-base gst-plugins-good \
  gst-plugins-ugly gstreamer libmtp libplist libxml2 pkgconf \
  protobuf qt@5 sqlite wget

BREW_PREFIX="$(brew --prefix)"
QT5_PREFIX="$(brew --prefix qt@5)"
GETTEXT_PREFIX="$(brew --prefix gettext)"
LIBXML2_PREFIX="$(brew --prefix libxml2)"

export HOMEBREW_PREFIX="$BREW_PREFIX"
export PATH="$QT5_PREFIX/bin:$GETTEXT_PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$QT5_PREFIX/lib/pkgconfig:$GETTEXT_PREFIX/lib/pkgconfig:$LIBXML2_PREFIX/lib/pkgconfig:$BREW_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="$QT5_PREFIX;$GETTEXT_PREFIX;$LIBXML2_PREFIX;$BREW_PREFIX"
export Qt5_DIR="$QT5_PREFIX/lib/cmake/Qt5"
export Qt5LinguistTools_DIR="$QT5_PREFIX/lib/cmake/Qt5LinguistTools"
export GST_SCANNER_PATH="$BREW_PREFIX/opt/gstreamer/libexec/gstreamer-1.0/gst-plugin-scanner"
export GST_PLUGIN_PATH="$BREW_PREFIX/lib/gstreamer-1.0"

if [[ "$BREW_PREFIX" == "/usr/local" && ! -e /usr/local/opt/qt5 ]]; then
  ln -s "$QT5_PREFIX" /usr/local/opt/qt5
fi

python3 .github/scripts/patch_macdeploy_homebrew_rpath.py

REVISION="1.4.0rc2-${GITHUB_RUN_NUMBER}-g${GITHUB_SHA}"
cmake -S . -B bin -Wno-dev -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DFORCE_GIT_REVISION="$REVISION" \
  -DGETTEXT_MSGMERGE_EXECUTABLE="$GETTEXT_PREFIX/bin/msgmerge" \
  -DGETTEXT_MSGFMT_EXECUTABLE="$GETTEXT_PREFIX/bin/msgfmt" \
  -DGETTEXT_XGETTEXT_EXECUTABLE="$GETTEXT_PREFIX/bin/xgettext" \
  -DENABLE_AUDIOCD=OFF -DENABLE_BREAKPAD=OFF -DENABLE_BOX=OFF \
  -DENABLE_DROPBOX=OFF -DENABLE_GOOGLE_DRIVE=OFF -DENABLE_LIBGPOD=OFF \
  -DENABLE_LIBLASTFM=OFF -DENABLE_LIBMTP=OFF -DENABLE_MOODBAR=OFF \
  -DENABLE_SEAFILE=OFF -DENABLE_SKYDRIVE=OFF -DENABLE_SPARKLE=OFF \
  -DENABLE_SPOTIFY_BLOB=OFF -DENABLE_VISUALISATIONS=OFF -DENABLE_WIIMOTEDEV=OFF

cmake --build bin --parallel 2
cmake --build bin --target install --parallel 2
codesign --force --deep --sign - bin/clementine.app || true
cmake --build bin --target dmg --parallel 2

SHORT_SHA="${GITHUB_SHA::7}"
DESCRIBE="$(git describe --tags --always --dirty 2>/dev/null || echo "$SHORT_SHA")"
SAFE_DESCRIBE="$(echo "$DESCRIBE" | tr '/ ' '--')"
mkdir -p release
cp "$(find bin -maxdepth 1 -name 'clementine-*.dmg' -print -quit)" "release/Clementine-macOS-x86_64-${SAFE_DESCRIBE}-${SHORT_SHA}.dmg"
