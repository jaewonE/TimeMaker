# TimeMaker architecture

[한국어 문서](ARCHITECTURE.ko.md)

## Runtime shape

TimeMaker is a menu-bar-only app (`LSUIElement`) composed of native macOS frameworks:

- `MenuBarController` owns the `NSStatusItem`, live title, left-click timer-window toggle, and right-click start/pause/resume action.
- `MainPanelController` owns an independent, movable borderless `NSPanel` with the timer UI's single custom close control.
- `WorkspaceWindowController` owns the shared Analytics/Settings `NSWindow` and sidebar navigation.
- SwiftUI renders all three surfaces while AppKit manages menu-bar and window behavior.

## Timer state flow

`TimerStore` is the single source of truth for idle, running, and paused state. A running timer stores a deadline instead of decrementing a counter as its authoritative time source. The 250 ms UI ticker derives the displayed whole seconds from that deadline. This prevents drift and lets the timer recover after display sleep, system sleep, or process restart. Minute adjustment is clamped at the supported bounds. `ScrollWheelMonitor` accumulates physical movement using one of six discrete sensitivity choices (0.5×, 1×, 2×, 3×, 4×, or 5×), then applies the separately configured timer increment. Minutes apply an additional 2× sensitivity. Idle adjustment remains always available; the default-off active-timer setting additionally allows scroll changes while running or paused. An active change updates the running deadline or paused remainder and adjusts only the current session's planned duration.

The persisted state contains:

- phase and configured duration;
- remaining time for paused sessions;
- deadline for running sessions;
- activity label and original session start;
- active time accumulated before pauses.

On completion, the store records exactly one session, optionally sends a native notification, resets the countdown to the configured duration, and retains the last label. When sound is enabled it plays the built-in `Glass.aiff` chime directly; clicking the notification reopens the timer window. A user reset also returns to the configured duration; its elapsed active time is written as a session only when the related setting is enabled.

## Persistence

`HistoryStore` writes an atomically replaced, versioned JSON document under Application Support. The document contains completed sessions and normalized label-use counters. Its period-based clear operation removes only completed sessions whose end time falls within the selected preset range; saved label suggestions remain. Preferences and active-timer recovery state use `UserDefaults`.

Label identity normalizes whitespace, hyphens, underscores, and English case. Autocomplete uses that canonical form for substring matching, then orders results by usage count, recency, and label.

## Analytics

`AnalyticsBuilder` is a pure `TimeMakerCore` transformation. It produces seven daily totals, activity totals, an active-day average, and a current streak from stored sessions. `AnalyticsView` renders those values with Swift Charts and native summary cards.

## System integrations

- `SMAppService.mainApp` registers or unregisters TimeMaker as a login item.
- `UNUserNotificationCenter` presents the completion notification and routes its default click action to the timer panel; `NSSound` plays the optional built-in `Glass.aiff` chime without depending on notification-sound permission.
- `NSAppearance` applies System, Light, or Dark selection across both windows.

## Packaging

Swift Package Manager builds the executable. `scripts/build_app.sh` assembles the standard `.app` layout, copies localizations and `.icns`, applies an ad-hoc signature, and verifies the bundle. `scripts/package_release.sh` creates the versioned ZIP and SHA-256 file used by GitHub Releases.
