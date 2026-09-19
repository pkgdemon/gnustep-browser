# Gershwin Browser

A native [GNUstep](https://gnustep.github.io/) web browser powered by **real WebKit**.

Not a wrapper around Chromium, and not a partial HTML renderer — this is the actual
WebKit engine (WPE WebKit) rendering into an AppKit `NSView`, with HarfBuzz text
shaping, Skia rasterisation and libsoup networking.

![Gershwin Browser](docs/screenshot.png)

## Features

- Tabs
- Back / forward / reload / stop
- URL bar — explicit schemes pass through, bare hostnames get `https://`,
  anything else becomes a search
- Load progress and status line
- Per-tab titles
- In-page error pages
- Menu with the usual shortcuts (Cmd-N / T / W / L / R, Cmd-[ and Cmd-])
- `--snapshot` for headless page capture

## Requirements

- GNUstep (base, gui, back) installed under `/System`
- `WebKit.framework` in `/System/Library/Frameworks` — see below
- An X display

---

## Part 1 — Build and install WebKit

The browser needs `WebKit.framework`, which is built from a WebKit fork carrying a
GNUstep API layer. **This part takes 1.5–3 hours** and needs roughly 20 GB of disk.

### 1.1 Install build dependencies

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ninja-build ruby gperf unifdef cmake clang \
  libglib2.0-dev libharfbuzz-dev libicu-dev libjpeg-dev libpng-dev libwebp-dev \
  libepoxy-dev libgcrypt20-dev libsoup-3.0-dev libtasn1-6-dev libxkbcommon-dev \
  libxml2-dev libxslt1-dev libsqlite3-dev zlib1g-dev \
  libfreetype-dev libfontconfig-dev \
  libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev libdrm-dev
```

`bison` and `flex` are **not** needed. `ruby` and `gperf` are required by WebKit's
code generators and the build fails early without them.

### 1.2 Clone the fork

```sh
git clone https://github.com/pkgdemon/WebKit.git
cd WebKit
```

### 1.3 Configure

Set **all** install paths in one go — each lands in a generated config header, so
changing them later forces a partial rebuild.

```sh
export LANG=C.UTF-8 LC_ALL=C.UTF-8

cmake -S . -B ../webkit-build -GNinja \
  -DPORT=WPE -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DENABLE_WPE_PLATFORM=ON -DENABLE_WPE_PLATFORM_HEADLESS=ON \
  -DENABLE_WPE_GNUSTEP_API=ON \
  -DENABLE_WPE_LEGACY_API=OFF -DENABLE_WPE_PLATFORM_DRM=OFF \
  -DENABLE_WPE_PLATFORM_WAYLAND=OFF -DUSE_GBM=OFF -DUSE_LIBDRM=ON \
  -DENABLE_WEBDRIVER=OFF \
  -DUSE_GSTREAMER=OFF -DENABLE_VIDEO=OFF -DENABLE_WEB_AUDIO=OFF \
  -DENABLE_WEB_CODECS=OFF -DENABLE_SPEECH_SYNTHESIS=OFF \
  -DENABLE_MEDIA_STREAM=OFF -DENABLE_MEDIA_RECORDER=OFF \
  -DUSE_AVIF=OFF -DUSE_JPEGXL=OFF -DUSE_WOFF2=OFF \
  -DENABLE_SPELLCHECK=OFF -DUSE_LIBHYPHEN=OFF \
  -DENABLE_INTROSPECTION=OFF -DENABLE_DOCUMENTATION=OFF \
  -DENABLE_JOURNALD_LOG=OFF -DUSE_LIBBACKTRACE=OFF \
  -DENABLE_BUBBLEWRAP_SANDBOX=OFF -DUSE_ATK=OFF -DUSE_FLITE=OFF \
  -DENABLE_GAMEPAD=OFF -DENABLE_WEBXR=OFF -DENABLE_MINIBROWSER=OFF \
  -DCMAKE_INSTALL_PREFIX=/System \
  -DCMAKE_INSTALL_LIBDIR=Library/Libraries \
  -DCMAKE_INSTALL_INCLUDEDIR=Library/Headers \
  -DCMAKE_INSTALL_DATADIR=Library/Application\ Support \
  -DLIB_INSTALL_DIR=/System/Library/Libraries \
  -DEXEC_INSTALL_DIR=/System/Library/Tools \
  -DLIBEXEC_INSTALL_DIR=/System/Library/Libraries/wpe-webkit-2.0
```

Confirm the GNUstep layer was found:

```
-- Found GNUstep: /System/Library/Tools/gnustep-config
--  ENABLE_WPE_GNUSTEP_API ................................. ON
```

### 1.4 Build

```sh
ninja -C ../webkit-build -j$(nproc)
```

Roughly 8,800 targets. Use fewer jobs if you have little RAM and no swap — the
link steps are memory hungry.

### 1.5 Install

```sh
sudo ninja -C ../webkit-build install
sudo ldconfig
```

Two workarounds are currently needed. WebKit's `wpe-webkit.pc.in` hardcodes
`includedir=${prefix}/include` and ignores `CMAKE_INSTALL_INCLUDEDIR`, so add a
compatibility symlink:

```sh
sudo ln -sfn Library/Headers /System/include
```

The framework installs its umbrella header as `WebKitGNUstep.h`, but the browser
imports `<WebKit/WebKit.h>`, so add it under that name too:

```sh
sudo ln -s WebKitGNUstep.h /System/Library/Frameworks/WebKit.framework/Versions/0/Headers/WebKit.h
```

### 1.6 Verify

```sh
ls /System/Library/Frameworks/WebKit.framework/Versions/Current/libWebKit.so
ls /System/Library/Libraries/wpe-webkit-2.0/WPEWebProcess
ls /System/Library/Headers/WebKit/WebView.h
```

Installed layout:

| Path | Contents |
|---|---|
| `/System/Library/Libraries/libWPEWebKit-2.0.so.*` | the engine (~148 MB) |
| `/System/Library/Libraries/wpe-webkit-2.0/` | `WPEWebProcess`, `WPENetworkProcess`, injected bundle |
| `/System/Library/Frameworks/WebKit.framework/` | the GNUstep framework |
| `/System/Library/Headers/WebKit` -> framework Headers | so `#import <WebKit/WebKit.h>` works |
| `/System/Library/Libraries/libWebKit.so` -> framework binary | so `-lWebKit` works |

### 1.7 Optional — video and audio (GStreamer)

The steps above build WebKit without media support, so `<video>` and `<audio>` do
not work. Sites that assume they do can break; for example, imgur.com renders and
then goes grey. WPE plays media through GStreamer, which decodes most formats with
FFmpeg via `gstreamer1.0-libav`.

Install GStreamer:

```sh
sudo apt-get install -y --no-install-recommends \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav
```

Optional, Devuan only: if Mesa comes from `excalibur-backports`, apt stops with
`libgbm-dev : Depends: libgbm1 (= …)`. Add `libgbm-dev/excalibur-backports` to the
end of the command above so `libgbm-dev` matches the installed `libgbm1`.

Reconfigure with the extra arguments. CMake keeps every other setting from 1.3:

```sh
export LANG=C.UTF-8 LC_ALL=C.UTF-8

cmake -S . -B ../webkit-build \
  -DUSE_GSTREAMER=ON -DENABLE_VIDEO=ON -DENABLE_WEB_AUDIO=ON -DENABLE_MEDIA_SOURCE=ON
```

Confirm media support is on:

```
--  ENABLE_VIDEO ........................................... ON
--  ENABLE_WEB_AUDIO ....................................... ON
--  ENABLE_MEDIA_SOURCE .................................... ON
--  USE_GSTREAMER .......................................... ON
```

Then build and install again as in 1.4 and 1.5. Turning video on means most of
WebCore rebuilds, so this takes about as long as the first build. The symlinks
from 1.5 are kept.

---

## Part 2 — Build and install the browser

Fast — seconds, not hours.

```sh
git clone https://github.com/pkgdemon/gershwin-browser.git
cd gershwin-browser
make
sudo make install GNUSTEP_INSTALLATION_DOMAIN=LOCAL
```

Installs to `/Local/Applications/Browser.app`.

## Run

```sh
/Local/Applications/Browser.app/Browser
/Local/Applications/Browser.app/Browser https://example.com

# headless capture
/Local/Applications/Browser.app/Browser https://example.com --snapshot out.png
```

---

## How it works

```
  Browser.app                    (GNUstep / AppKit, Objective-C)
      |
  WebKit.framework               WebView : NSView
      |                          - SHM frame -> NSBitmapImageRep -> -drawRect:
      |                          - NSEvent -> WPEEvent
      |                          - GMainContext pumped from NSRunLoop
      |
  libWPEWebKit-2.0.so            UIProcess | WebProcess | NetworkProcess
      |
  Skia | HarfBuzz | libsoup | Mesa EGL
```

The engine renders offscreen into shared-memory buffers via WPEPlatform's headless
display. `WebKit.framework` converts each frame to an `NSBitmapImageRep` and blits
it into the view. Because WebKit's UIProcess is not thread-safe and WTF's
`RunLoopGLib` owns the default `GMainContext`, all WebKit calls happen on the AppKit
main thread and the GLib loop is driven from `NSRunLoop`.

## Known gaps

No `<video>`/`<audio>` unless WebKit is built with the optional GStreamer step
(1.7), which is off by default to halve build time. `target=_blank` and
`window.open` open a new tab, but the page gets its own web process, so
`window.opener` and named targets do not connect. No context menus, script
dialogs, file chooser, downloads, bookmark or history persistence,
find-in-page, or IME yet. WebGL is compiled in.

## Licence

The browser is provided under the same terms as its dependencies; see the WebKit and
GNUstep projects for theirs.
