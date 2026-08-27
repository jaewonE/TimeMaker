# TimeMaker

[한국어 문서](README.ko.md)

TimeMaker is a native macOS Pomodoro timer that lives in the menu bar. It is built with SwiftUI and AppKit—no Electron, embedded browser, or remote service is used.

## Highlights

- Live `MM:SS` countdown in the menu bar, including durations above one hour such as `90:00`.
- Compact floating timer panel modeled after the supplied visual references.
- Activity labels with frequency-ranked autocomplete from previously used labels.
- Scroll-adjustable minutes and seconds with a configurable step from 1 to 60.
- Presets for 5, 10, 15, 30, 60, and 90 minutes.
- Pause/resume support and deadline-based timing that remains accurate across sleep and app restarts.
- Today progress dots: each full dot is one hour, while a dashed partial dot shows the remaining minutes as an angle.
- Local analytics with seven-day focus bars, activity breakdown, streaks, summaries, and recent sessions.
- System/light/dark appearance options.
- Native macOS login-item registration and silent completion notifications.
- English and Korean interface localizations.

## Requirements

- macOS 14 Sonoma or later
- The packaged `v1.0.0` artifact is built for Apple Silicon (`arm64`)
- Xcode 15.3 or later and Swift 5.10 or later when building from source

## Install

The locally built app is installed at `/Applications/TimeMaker.app`.

For a release download:

1. Download `TimeMaker-1.0.0-macOS-arm64.zip` from the private GitHub release.
2. Extract it and move `TimeMaker.app` to `/Applications`.
3. On the first launch, Control-click the app and choose **Open** if Gatekeeper asks for confirmation.
4. Allow notifications when macOS asks. TimeMaker sends banners without sound.

The release is ad-hoc signed because no Apple Developer signing identity is available on the build Mac. It is code-signed and verified locally, but it is not notarized by Apple.

## Use

- Left-click the menu-bar countdown to show or hide the timer panel.
- Right-click the countdown for Timer, Analytics, and Settings menus.
- Scroll over the minute or second value while the timer is idle to change it.
- Type an activity such as `Work`, `Reading`, or `Writing`; matching previous labels appear below the field, most frequently used first.
- Press Play to start. When **Hide window when timer starts** is enabled, the panel closes and the menu-bar countdown remains visible.
- Reopen the panel to pause or resume.

TimeMaker keeps the last activity label after a timer completes. A new installation starts with `Work` and `30:00`.

## Settings

| Setting | Default | Range / choices |
| --- | --- | --- |
| Scroll step | 5 | 1–60 |
| Open at login | On | On / Off |
| Hide window when timer starts | On | On / Off |
| Color mode | System | System / Light / Dark |
| Allow notifications | On | On / Off; silent native notification |

## Data and privacy

TimeMaker has no account, analytics SDK, telemetry, or network dependency. Timer sessions and label-use counts stay in:

```text
~/Library/Application Support/TimeMaker/history.json
```

Preferences and recoverable active-timer state use the standard macOS preferences domain `com.jaewone.timemaker`.

## Build and test

```bash
swift test
./scripts/build_app.sh
./scripts/install_app.sh
./scripts/package_release.sh
```

Build outputs are written to `dist/` and are excluded from Git. See [Architecture](docs/ARCHITECTURE.md) for the data flow and implementation boundaries.

## License

All rights reserved. This repository is private unless the owner explicitly changes its distribution terms.
