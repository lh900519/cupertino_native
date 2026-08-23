## Context

`CNTabBar` renders with `UITabBar` on iOS, `NSSegmentedControl` on macOS, and `CupertinoTabBar` elsewhere. The Dart widget already resolves theme-dependent colors and sends a `style` map at creation, then incrementally sends `setStyle` updates. That style currently contains selected `tint` and background color only, so normal label text cannot be themed consistently.

The change crosses the public Dart API, the platform-channel contract, both native renderers, and the fallback. It must also handle dynamic `Color` resolution and removal of an explicitly configured value without recreating the platform view.

## Goals / Non-Goals

**Goals:**

- Expose one optional `Color? labelColor` on `CNTabBar` for normal/unselected label text.
- Keep `tint` as the selected-state accent and avoid changing icon color semantics.
- Support initial rendering, runtime value changes, clearing back to the native default, brightness-dependent colors, single and split layouts, and the non-Apple fallback.
- Preserve source and visual compatibility when the property is omitted.

**Non-Goals:**

- Per-item or per-state label colors beyond the existing selected/unselected distinction.
- Label typography, font size, weight, or layout customization.
- Changing SF Symbol tint behavior.
- Replacing native tab controls with Flutter-rendered controls.

## Decisions

### Add `labelColor` at the bar level

The public API will add `final Color? labelColor` to `CNTabBar`, defaulting to `null`. A bar-level value matches existing properties such as `tint` and `backgroundColor`, and expresses the requested default consistently across all items. Per-item colors were rejected because native tab appearances are primarily state-wide and would substantially expand the channel contract.

### Treat the property as the normal/unselected label color

`labelColor` will affect label text only while an item is not selected. Selected label appearance remains governed by the existing `tint`/native selected appearance. This keeps the two properties orthogonal and avoids silently changing existing selected-state behavior.

Native label styling is reapplied after assigning or rebuilding tab bar items because newer UIKit versions reconstruct floating tab bar content during item assignment.

### Extend the existing style payload with nullable update semantics

Dart will resolve `labelColor` through `resolveColorToArgb`, add `labelColor` to creation-time `style`, cache the last resolved value, and synchronize changes through `setStyle`. Runtime synchronization must send the key even when the new value is `null`; native handlers will distinguish an explicit null/`NSNull` from an absent key and restore system defaults. This is preferred over adding a dedicated method because color styling already shares one channel path.

### Use each renderer's native state appearance

- iOS will set `UITabBar.unselectedItemTintColor`, normal title foreground color on every `UITabBarItemAppearance` layout variant (`stacked`, `inline`, and `compactInline`), and each `UITabBarItem` normal-state title attribute. Because iOS 26 floating tab bars can ignore all three public color paths, a `UITabBar` subclass also reapplies the color to unselected descendant labels after native layout while preserving cached system colors for selected and reset states. The component's images use `.alwaysOriginal`, so their colors remain unchanged. The same application path covers single and split bars.
- macOS will retain `NSSegmentedControl` behavior and introduce a focused `NSSegmentedCell` drawing customization for text segments: the system continues drawing the bezel and selected content, while unselected label content is drawn with the configured color. Clearing the value delegates all content drawing back to AppKit. Selection, content, appearance, and style changes will invalidate/reapply the control.
- The Flutter fallback will map `labelColor` to `CupertinoTabBar.inactiveColor`, using the current `CupertinoColors.inactiveGray` when it is null.

Using native state appearance is preferred to overlaying Flutter labels, which would complicate hit testing, intrinsic sizing, accessibility, and platform fidelity.

### Verify the channel contract and observable fallback

Dart tests will verify public-property mapping, nullable style updates, and fallback `inactiveColor`. Native tests or build-level verification will cover parsing and state application where the repository's current test infrastructure permits. The example tab bar will demonstrate a non-default label color.

## Risks / Trade-offs

- **[macOS custom text drawing can drift from AppKit metrics]** → Preserve system bezel/selected drawing, use the cell-provided content frame and system font/alignment, and limit custom drawing to unselected text segments with an explicit color.
- **[iOS has multiple tab item layout appearances]** → Configure all three `UITabBarItemAppearance` variants rather than only the current stacked layout.
- **[iOS 26 floating tab bars ignore public unselected title color APIs]** → Apply a narrowly scoped post-layout UILabel compatibility pass based on public control selection state, retaining system colors for selected and reset states.
- **[A null update can be mistaken for a missing key]** → Check key presence explicitly in native `setStyle` handlers and test color-to-null transitions.
- **[Dynamic colors can change without widget identity changes]** → Cache the resolved ARGB value and run synchronization from `didChangeDependencies`, matching the existing tint/background flow.
- **[Selected and unselected colors can have poor contrast]** → Leave color choice to callers and preserve native defaults when no color is supplied.

## Migration Plan

No consumer migration is required because the property is optional. Release the Dart and native changes atomically. If native rendering regressions occur, callers can omit `labelColor`; rollback consists of removing the optional API/payload field and native handling without data migration.

## Open Questions

None.
