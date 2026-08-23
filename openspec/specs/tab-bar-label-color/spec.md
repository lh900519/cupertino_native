# tab-bar-label-color Specification

## Purpose
TBD - created by archiving change add-tab-bar-label-color. Update Purpose after archive.
## Requirements
### Requirement: Configurable default tab label color
`CNTabBar` SHALL expose an optional bar-level `labelColor` value that controls the text color of labels for unselected items, without changing icon colors or the selected-state `tint` behavior.

#### Scenario: Custom color is configured
- **WHEN** a `CNTabBar` is built with a non-null `labelColor`
- **THEN** each visible unselected item label uses the resolved configured color
- **AND** the selected label continues to use the existing selected appearance

#### Scenario: Label color is omitted
- **WHEN** a `CNTabBar` is built without `labelColor`
- **THEN** unselected labels use the renderer's existing system-default color

#### Scenario: An item has no label
- **WHEN** an item contains only an icon and the bar has a `labelColor`
- **THEN** the configured label color does not alter that item's icon color

### Requirement: Consistent renderer support
The system SHALL apply `labelColor` consistently to iOS and macOS native renderers and to the non-Apple Flutter fallback.

#### Scenario: iOS native tab bar
- **WHEN** iOS renders a single or split `CNTabBar` with `labelColor`
- **THEN** every native tab item layout uses that value for normal label text

#### Scenario: macOS native tab bar
- **WHEN** macOS renders a `CNTabBar` with `labelColor`
- **THEN** unselected text segments use that value while AppKit retains native control interaction and selected-state rendering

#### Scenario: Flutter fallback
- **WHEN** a non-Apple platform renders a `CNTabBar` with `labelColor`
- **THEN** the fallback `CupertinoTabBar` uses that value as its inactive color

### Requirement: Runtime and adaptive color updates
The system SHALL synchronize changes to the resolved `labelColor` with an existing native tab bar without requiring platform-view recreation.

#### Scenario: Label color changes
- **WHEN** the widget updates from one non-null `labelColor` to another
- **THEN** all unselected native labels update to the newly resolved color

#### Scenario: Label color is cleared
- **WHEN** the widget updates from a non-null `labelColor` to null
- **THEN** native and fallback renderers restore their existing system-default unselected label color

#### Scenario: Dynamic color resolves differently
- **WHEN** a dynamic `labelColor` resolves to a different ARGB value after inherited theme or brightness changes
- **THEN** the native renderer receives and applies the new resolved value
