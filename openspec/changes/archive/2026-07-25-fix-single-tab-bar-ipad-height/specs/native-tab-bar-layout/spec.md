## ADDED Requirements

### Requirement: iPad stacked tab-bar layout

On iPad, the native tab bar SHALL use a compact-width stacked icon-above-title layout for Single mode. In Split mode, the left bar SHALL use that layout when it contains more than one item. The right Split bar SHALL remain a normal native tab bar.

#### Scenario: iPad Single mode

- **WHEN** a Single-mode tab bar is displayed on iPad
- **THEN** each item with an icon and title displays the icon above the title

#### Scenario: iPad Split mode with multiple left tabs

- **WHEN** Split mode is displayed on iPad and the left bar contains more than one item
- **THEN** the left bar uses stacked icon/title items and the right bar remains independent

#### Scenario: iPad Split mode with one left tab

- **WHEN** Split mode is displayed on iPad and the left bar contains one item
- **THEN** the left bar keeps the default native layout

#### Scenario: iPhone compatibility

- **WHEN** a tab bar is displayed on iPhone
- **THEN** the implementation uses the baseline native `UITabBar` layout without the iPad stacked override

### Requirement: Preserve existing sizing and grouping

The iPad adaptation SHALL NOT change the existing Flutter sizing contract, native height constraints, Split-mode width calculation, tab selection behavior, or public Dart API.

#### Scenario: Split grouping

- **WHEN** Split mode is displayed on either device
- **THEN** left and right bars retain their existing grouping, spacing, and width constraints
