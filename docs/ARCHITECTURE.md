# TimeMaker architecture

[한국어 문서](ARCHITECTURE.ko.md)

## Runtime shape

TimeMaker is a menu-bar-only app (`LSUIElement`) composed of native macOS frameworks:

- `MenuBarController` owns the `NSStatusItem`, live title, left-click panel toggle, and right-click hierarchical menu.
- `MainPanelController` owns a borderless `NSPanel` anchored below the status item.
- `WorkspaceWindowController` owns the shared Analytics/Settings `NSWindow` and sidebar navigation.
- SwiftUI renders all three surfaces while AppKit manages menu-bar and window behavior.

## Timer state flow

`TimerStore` is the single source of truth for idle, running, and paused state. A running timer stores a deadline instead of decrementing a counter as its authoritative time source. The 250 ms UI ticker derives the displayed whole seconds from that deadline. This prevents drift and lets the timer recover after display sleep, system sleep, or process restart.

The persisted state contains:

- phase and configured duration;
- remaining time for paused sessions;
- deadline for running sessions;
- activity label and original session start;
- active time accumulated before pauses.

On completion, the store records exactly one session, optionally sends a silent native notification, resets the countdown to the configured duration, and retains the last label.

## Persistence

`HistoryStore` writes an atomically replaced, versioned JSON document under Application Support. The document contains completed sessions and normalized label-use counters. Preferences and active-timer recovery state use `UserDefaults`.

Autocomplete uses case- and diacritic-insensitive substring matching. Results are ordered by usage count, then recency, then label.

## Analytics

`AnalyticsBuilder` is a pure `TimeMakerCore` transformation. It produces seven daily totals, activity totals, an active-day average, and a current streak from stored sessions. `AnalyticsView` renders those values with Swift Charts and native summary cards.

## System integrations

- `SMAppService.mainApp` registers or unregisters TimeMaker as a login item.
- `UNUserNotificationCenter` requests alert-only authorization and deliberately omits sound.
- `NSAppearance` applies System, Light, or Dark selection across both windows.

## Packaging

Swift Package Manager builds the executable. `scripts/build_app.sh` assembles the standard `.app` layout, copies localizations and `.icns`, applies an ad-hoc signature, and verifies the bundle. `scripts/package_release.sh` creates the versioned ZIP and SHA-256 file used by GitHub Releases.
