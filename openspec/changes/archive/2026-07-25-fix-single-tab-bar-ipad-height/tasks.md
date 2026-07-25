## 1. iOS layout contract

- [x] 1.1 Add an internal iPad-only tab-bar subclass that requests compact-width stacked items.
- [x] 1.2 Apply the stacked subclass to iPad Single mode and iPad Split mode's multi-item left bar.
- [x] 1.3 Preserve iPhone's baseline native tab-bar layout.
- [x] 1.4 Preserve existing sizing, grouping, constraints, selection behavior, and public Dart APIs.

## 2. Regression validation

- [ ] 2.1 Run Single mode on iPhone and iPad simulators and verify only iPad receives stacked layout.
- [ ] 2.2 Verify iPad Split mode grouping and the right-bar layout remain unchanged.

## 3. Quality checks

- [x] 3.1 Run `flutter analyze`.
- [x] 3.2 Build the iOS Simulator target successfully.
- [x] 3.3 Update OpenSpec documentation for the iPad-only stacked behavior.
