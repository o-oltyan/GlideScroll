# GlideScroll

Smooth, trackpad-like scrolling for your mouse on macOS — plus optional scroll-direction reversal.

GlideScroll intercepts the choppy, line-by-line scroll events a mouse wheel produces and replaces them with smooth, pixel-based scrolling with an exponential ease-out, the way a trackpad feels. The trackpad itself (and Magic Mouse) is never touched.

## Features

- **Smooth scrolling** — each wheel notch glides instead of jumping, with adjustable smoothness and speed
- **Reverse scroll direction** — mouse only; the trackpad keeps its natural direction
- **Modifier keys** — hold **Shift** to scroll horizontally, hold **Option** to temporarily disable smoothing (both toggleable)
- **Menu bar item** with quick toggles — and an app-level setting to hide it entirely
- **Settings window** opens when you launch the app from Finder / Spotlight / Raycast, so everything stays configurable even with the menu bar icon hidden
- **Launch at login**
- **About** page with version and license

## Install

1. Download `GlideScroll-x.y.z.dmg` from [Releases](https://github.com/o-oltyan/GlideScroll/releases)
2. Drag **GlideScroll** to **Applications**
3. First launch: **right-click → Open** (the app is not notarized)
4. Grant **Accessibility** access when prompted (System Settings → Privacy & Security → Accessibility). macOS requires this for apps that modify scroll events. The app picks the grant up automatically — no relaunch needed.

To open the settings later: click the menu bar icon, or just launch GlideScroll again from Spotlight — the window reappears.

## Build from source

```sh
Scripts/build-app.sh            # → dist/GlideScroll.app
open dist/GlideScroll.app
```

Requires Xcode command line tools (Swift 6, macOS 15+ SDK).

### Note on rebuilding and Accessibility

The default build is ad-hoc signed, and macOS ties the Accessibility grant to the exact binary — so **after every rebuild you must re-grant access** (remove and re-add the app in System Settings, or `tccutil reset Accessibility com.oltyan.GlideScroll`). For development, create a self-signed code-signing certificate named `GlideScroll Dev` in Keychain Access (Certificate Assistant → Create a Certificate → type: Code Signing) and build with:

```sh
SIGN_IDENTITY="GlideScroll Dev" Scripts/build-app.sh
```

The identity-based signature is stable across builds and the permission sticks.

## Release

```sh
brew install create-dmg   # once
VERSION=1.0.0 Scripts/release.sh
```

## Caveats

- **Magic Mouse** scrolls with the same continuous event signature as the built-in trackpad, so GlideScroll cannot distinguish it and leaves it untouched (it is already smooth; reversal does not apply to it either).
- Smoothing swallows the original wheel events and re-posts synthetic ones; a handful of apps that read raw HID input (some games, VMs, screen-sharing clients) may prefer the **Option** bypass.

## License

[MIT](LICENSE) — © 2026 Octa Oltyan
