## Why

The `d4122e9` baseline uses UIKit's default tab-bar layout on every device. On iPad, the regular horizontal size class can select an inline icon/title arrangement, so the component needs an iPad-specific stacked layout while keeping iPhone behavior unchanged.

## What Changes

- Use a stacked icon-above-title tab bar for iPad Single mode.
- Use the same layout for the left side of iPad Split mode when it has multiple items.
- Keep iPhone's native layout and the existing sizing, grouping, and constraints unchanged.

## Scope

### New Capability

- `native-tab-bar-layout`: Defines cross-device Single-mode item layout, sizing, and bottom-offset behavior for the native tab bar.

### Modified Capability

None.

## Impact

- Updates `ios/Classes/Views/CupertinoTabBarPlatformView.swift` with the iPad-only trait selection.
- Updates OpenSpec documentation for the platform-specific behavior.
- Does not add dependencies, public Dart APIs, or macOS changes.
