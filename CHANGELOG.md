# Changelog

## \[Unreleased\]

## [9.0.0] - 2026-05-10

> **Note on version numbering**: Versions 1.x – 7.0.5 of `gg` on pub.dev
> were a *different* package — a Dart pre-commit / workflow tool, now
> renamed upstream to `gg_one`. This release (9.0.0) is the first
> publication of the **new** `gg` package, which is the successor to
> the `kd` package (formerly at `kd 3.1.0`). The major version was
> bumped past the old `gg` 7.x range to make the discontinuity clearly
> visible and to satisfy pub.dev's no-downgrade rule.

### Changed

- **BREAKING**: Renamed package from `kd` to `gg`. Repository moved to
  https://github.com/ggsuite/gg. Update `dependencies:` entries and
  `import 'package:kd/...'` statements to `import 'package:gg/...'`.
  The executable is now `gg` (previously `kd`).
- **BREAKING**: Replaced dependency `gg ^7.0.5` with `gg_one ^8.0.0`
  (the upstream `gg` package was renamed to `gg_one`).
- **BREAKING**: Replaced dependency `kidney_core ^3.1.0` with
  `gg_multi ^4.0.0` (the upstream `kidney_core` package was renamed
  to `gg_multi`).
- Renamed source files (`bin/kd.dart` → `bin/gg.dart`, `lib/kd.dart`
  → `lib/gg.dart`, `lib/src/commands/kidney*.dart` →
  `lib/src/commands/gg*.dart`, tests, example).
- Renamed Flutter web build directory `kidney_ui/` to `gg_multi_ui/`
  (alignment with `gg_multi` naming).
- Renamed status marker file `.kidney_status` to `.gg_multi_status`.

## [3.1.0] - 2026-05-04

### Changed

- Bump gg dependency to 7.0.5

## [3.0.4] - 2026-04-29

## [3.0.3] - 2026-04-28

## [3.0.2] - 2026-04-28

## [3.0.1] - 2026-04-24

## [3.0.0] - 2026-04-23

## [2.6.1] - 2026-04-15

## [2.6.0] - 2026-04-14

## [2.5.2] - 2026-04-13

## [2.5.1] - 2026-04-08

## [2.5.0] - 2026-04-08

### Changed

- kidney: changed references to local

## [2.4.0] - 2026-04-07

## [2.3.0] - 2026-04-01

## [2.2.2] - 2026-03-31

## [2.2.1] - 2026-03-30

## [2.2.0] - 2026-03-30

## [2.1.2] - 2026-03-29

## [2.1.1] - 2026-03-27

## [2.1.0] - 2026-03-27

### Removed

- remove publish\_to:none

## [2.0.0] - 2026-03-26

### Changed

- kidney: changed references to path
- kidney: changed references to git
- Kidney: changed references to pub.dev

### Fixed

- small fixes in tests and version upgrades

## [1.1.0] - 2026-03-26

## [1.0.0] - 2026-03-25

### Changed

- commit

[3.1.0]: https://github.com/ggsuite/kd/compare/3.0.4...3.1.0
[3.0.4]: https://github.com/ggsuite/kd/compare/3.0.3...3.0.4
[3.0.3]: https://github.com/ggsuite/kd/compare/3.0.2...3.0.3
[3.0.2]: https://github.com/ggsuite/kd/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/ggsuite/kd/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/ggsuite/kd/compare/2.6.1...3.0.0
[2.6.1]: https://github.com/ggsuite/kd/compare/2.6.0...2.6.1
[2.6.0]: https://github.com/ggsuite/kd/compare/2.5.2...2.6.0
[2.5.2]: https://github.com/ggsuite/kd/compare/2.5.1...2.5.2
[2.5.1]: https://github.com/ggsuite/kd/compare/2.5.0...2.5.1
[2.5.0]: https://github.com/ggsuite/kd/compare/2.4.0...2.5.0
[2.4.0]: https://github.com/ggsuite/kd/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/ggsuite/kd/compare/2.2.2...2.3.0
[2.2.2]: https://github.com/ggsuite/kd/compare/2.2.1...2.2.2
[2.2.1]: https://github.com/ggsuite/kd/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/ggsuite/kd/compare/2.1.2...2.2.0
[2.1.2]: https://github.com/ggsuite/kd/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/ggsuite/kd/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/ggsuite/kd/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/ggsuite/kd/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/ggsuite/kd/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/ggsuite/kd/tag/%tag
