# Changelog

## [Unreleased]

### Added

- --save-state option for commands like gg can commit\n\nThis is needed to make GitHub pipelines work
- Setup pipeline git username and email

### Removed

- Removed unused sample project
- logStatus is replaced by GgStatusPrinter

## [1.0.14] - 2024-04-05

### Added

- gg do commit/publish edits CHANGELOG.md

### Fixed

- Broken links in CHANGELOG.md, wrong commit messages
- Remove unneccessary commandline output

## [1.0.12] - 2024-04-04

- Initial version

[Unreleased]: https://github.com/inlavigo/gg/compare/1.0.14...HEAD
[1.0.14]: https://github.com/inlavigo/gg/compare/1.0.12...1.0.14
[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12
