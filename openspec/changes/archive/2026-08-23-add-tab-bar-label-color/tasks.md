## 1. Dart API and Channel Contract

- [x] 1.1 Add the documented optional `labelColor` property to `CNTabBar` and map it to the fallback `CupertinoTabBar.inactiveColor` while retaining the existing null default.
- [x] 1.2 Resolve and include `labelColor` in native creation parameters, cache its resolved ARGB value, and send both non-null changes and explicit null resets through `setStyle`.
- [x] 1.3 Add Dart widget/channel tests for initial values, runtime changes, null restoration, dynamic color resolution, and fallback inactive color behavior.

## 2. iOS Native Rendering

- [x] 2.1 Extend the iOS style/configuration model and argument parsing to carry the optional label color at creation and during `setStyle` updates.
- [x] 2.2 Apply the configured color to normal title attributes for stacked, inline, and compact-inline item appearances and each native item on every single or split `UITabBar`, preserving selected tint and icon colors.
- [x] 2.3 Handle explicit null updates by restoring the system normal-title appearance, and add or update iOS verification for color changes and resets.

## 3. macOS Native Rendering

- [x] 3.1 Extend macOS creation and `setStyle` parsing to store an optional label color and distinguish explicit null resets from omitted style fields.
- [x] 3.2 Implement focused `NSSegmentedCell` label drawing so unselected text segments use `labelColor` while selected content, icon-only segments, bezels, sizing, and accessibility remain native.
- [x] 3.3 Reapply/invalidate macOS label appearance after selection, item, brightness, and style changes, and add or update verification for configured and reset states.

## 4. Example and Validation

- [x] 4.1 Update the tab bar example to demonstrate a custom default label color.
- [x] 4.2 Format changed Dart sources and run `flutter analyze` plus relevant Flutter tests.
- [x] 4.3 Build or test the iOS and macOS plugin targets to verify the Swift changes compile and the platform-channel contract remains valid.
