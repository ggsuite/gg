# Changelog

## [Unreleased]

### Changed

- Update latest changes on gg\_publish and gg\_git
- Refactor tests

## [2.0.2] - 2024-04-06

### Fixed

- Changes were not correctly submitted on publish

## [2.0.1] - 2024-04-06

### Changed

- Pipeline: Improve order and description of tasks
- Commit message of .gg.json commit

### Fixed

- doPush did not push success state result when state was pushed before

## [2.0.0] - 2024-04-06

### Added

- New sub command »gg info modified-files and »gg info »last-changes-hash«
- DoCommit: When everything is committed, no message an log type are needed.
- Option --no-log to allow committing without change CHANGELOG.md
- Pipeline: Print modified files + changes hash

### Changed

- Pipeline: Use globally installed version of gg
- Kidney: Auto check all repos
- Breaking change: Renamed log type values into add \| change \| deprecate \| fix \| remove \| secure

### Fixed

- Wrong option in command line output
- An error which can lead to sporadic test fails

## [1.0.16] - 2024-04-05

### Added

- Code to fix pipeline issues
- --force flag to tests on pipeline
- Renamed -l flag into -t for gg do commit

### Changed

- Cleaned up pipeline
- Prepare publishing

## [1.0.15] - 2024-04-05

### Added

- --save-state option for commands like gg can commit\n\nThis is needed to make GitHub pipelines work
- Setup pipeline git username and email
- pubspec.lock to .gitignore
- Add various outputs to test pipeline issues

### Removed

- Removed unused sample project
- logStatus is replaced by GgStatusPrinter
- isGitHub is replaced by gg\_is\_github
- Pipeline: remove --no-save-state flag

## [1.0.14] - 2024-04-05

### Added

- gg do commit/publish edits CHANGELOG.md

### Fixed

- Broken links in CHANGELOG.md, wrong commit messages
- Remove unneccessary commandline output

## [1.0.12] - 2024-04-04

- Initial version

[Unreleased]: https://github.com/inlavigo/gg/compare/2.0.2...HEAD
[2.0.2]: https://github.com/inlavigo/gg/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/inlavigo/gg/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/inlavigo/gg/compare/1.0.16...2.0.0
[1.0.16]: https://github.com/inlavigo/gg/compare/1.0.15...1.0.16
[1.0.15]: https://github.com/inlavigo/gg/compare/1.0.14...1.0.15
[1.0.14]: https://github.com/inlavigo/gg/compare/1.0.12...1.0.14
[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12
