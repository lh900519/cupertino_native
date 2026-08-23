## Why

`CNTabBar` currently exposes the selected tint but leaves unselected label text entirely to the native system appearance. Applications need a cross-platform way to set the default (unselected) label color so tab labels can follow their visual theme while retaining native rendering.

## What Changes

- Add an optional `labelColor` property to `CNTabBar` for the default color of unselected tab labels.
- Resolve dynamic Flutter colors and pass the configured label color through creation parameters and runtime style updates.
- Apply the color to normal/unselected tab label appearance on iOS and macOS without changing the selected `tint` behavior.
- Apply the same semantics to the non-Apple `CupertinoTabBar` fallback.
- Preserve the current system-default label appearance when `labelColor` is omitted.

## Capabilities

### New Capabilities

- `tab-bar-label-color`: Configurable default/unselected label color behavior for `CNTabBar` across supported renderers.

### Modified Capabilities

None.

## Impact

- Public Dart API: `lib/components/tab_bar.dart`.
- Platform-channel style payload and runtime synchronization.
- Native iOS `UITabBarAppearance` configuration and macOS `NSSegmentedControl` label styling.
- Example/demo coverage and automated tests for creation, updates, fallback behavior, and omitted-color compatibility.
- No new dependencies and no breaking API changes.
