## Background

The `d4122e9` baseline uses UIKit's default `UITabBar` layout for every device. On iPad, regular horizontal size classes can select an inline icon/title arrangement, which is not the intended appearance for this component.

## Goals and Non-Goals

**Goals:**

- Use a compact-width stacked icon-above-title layout for iPad Single mode.
- Use the same stacked layout for the left side of iPad Split mode when it contains multiple tabs.
- Preserve the existing iPhone layout and Split-mode grouping and sizing behavior.
- Keep the adaptation scoped to the native iOS implementation.

**Non-goals:**

- Do not force stacked layout on iPhone.
- Do not change tab-bar height measurement, Flutter sizing, safe-area handling, or public Dart APIs.
- Do not change macOS behavior or Split-mode width calculations.

## Technical Decisions

### iPad-only stacked tab bar

`IPadStackedTabBar` is an internal `UITabBar` subclass. On iOS 17 and later it sets `traitOverrides.horizontalSizeClass` to `.compact`, allowing UIKit to select stacked item presentation. The subclass is instantiated only when `UIDevice.current.userInterfaceIdiom == .pad`.

Single mode uses the subclass for all iPad tab counts. Split mode uses it only for the iPad left bar when more than one item is present; the right bar remains a normal `UITabBar`.

### iPhone compatibility

iPhone continues to instantiate the baseline `UITabBar`, so its existing compact layout, sizing, and interaction behavior are unchanged.

## Risks and Trade-offs

- The compact trait relies on UIKit behavior on iOS 17 and later; earlier iOS versions retain the default tab-bar layout.
- UIKit may adjust spacing as its tab-bar implementation evolves, but the change does not introduce custom item widths or appearance overrides.
