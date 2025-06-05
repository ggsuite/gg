# Changelog

## [Unreleased]

### Changed

- Improve error message
- Update to dart 3.8.0
- Don't add log type to commit message

## [3.0.17] - 2025-02-28

### Changed

- Upgrade to dart 3.7

## [3.0.16] - 2024-11-27

### Changed

- Replace gg\_json by gg\_direct\_json

## [3.0.15] - 2024-10-03

### Changed

- When commit with ammendWhenNotPushed = true is called and no upstream branch is set, changes will be ammended

### Fixed

- Fix pana issues

## [3.0.14] - 2024-09-04

### Changed

- Exclude l10 from coverage

## [3.0.13] - 2024-09-04

### Changed

- Don't expect tests for l10n folders

## [3.0.12] - 2024-08-30

### Changed

- Change launch.json
- Test change
- Prevent updating the hash for CanUpgrade.

## [3.0.11] - 2024-08-30

### Changed

- Pretty print .gg.json
- Hashes wil be calculated independent of line feeds

## [3.0.10] - 2024-08-30

### Changed

- Update dependencies to latest versions
- Make pana work on windows
- Run tests on MacOS

## [3.0.9] - 2024-08-24

### Changed

- Show detailed test errors when running on a github pipeline

## [3.0.8] - 2024-08-24

### Changed

- Update gg\_test to 1.0.19. Only failing error lines are shown, but not details.

## [3.0.7] - 2024-08-20

### Fixed

- Fix an issue with binary file hash calculation

## [3.0.6] - 2024-06-21

### Changed

- Update to new version of gg\_tests

## [3.0.5] - 2024-06-21

### Fixed

- Fix issue with generated files

## [3.0.4] - 2024-04-13

### Removed

- Removed neccessity to specify a log type when running »gg do commit«

## [3.0.3] - 2024-04-13

### Added

- missing ✅ for message Tag 1.2.3 added

## [3.0.2] - 2024-04-13

### Changed

- Use a globally installed pana to make pana check

### Removed

- dependency pana

## [3.0.1] - 2024-04-13

### Added

- mocks for DidPush, DidPublish
- DidUpgrade
- CanUpgrade, Improve mocks
- upgrade dependencies and make tests work again
- Tests for DoUpgrade
- did upgrade only checks if changes are available on pub.dev
- DoMaintain to check if everything is upgraded and published from time to time

### Changed

- Parentheses are not necessary anymore
- improved comments of DidCommit, DidPublish and DidPush
- Improved help for CanCommit, CanPush, CanPublish
- DidUpgrade checks also if everything is upgraded

### Removed

- Upgrade check before pushing
- dependency to gg\_install\_gg, remove ./check script
- Upgrading does not trigger a commit and a publish

## [3.0.0] - 2024-04-10

### Changed

- BREAKING CHANGE: Interface of »gg do commit« has changed.

## [2.0.5] - 2024-04-10

### Fixed

- DoPublish: Don't confirm package not published to pub.dev, small fixes
- Pipeline: Disable cache

## [2.0.4] - 2024-04-09

### Changed

- Don't check pana on packages not published to pub.dev

### Fixed

- Various fixes to make non-pub.dev repos work

## [2.0.3] - 2024-04-09

### Added

- Handle unpublished packages as well packages that are not published to pub.dev

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

[Unreleased]: https://github.com/inlavigo/gg/compare/3.0.17...HEAD
[3.0.17]: https://github.com/inlavigo/gg/compare/3.0.16...3.0.17
[3.0.16]: https://github.com/inlavigo/gg/compare/3.0.15...3.0.16
[3.0.15]: https://github.com/inlavigo/gg/compare/3.0.14...3.0.15
[3.0.14]: https://github.com/inlavigo/gg/compare/3.0.13...3.0.14
[3.0.13]: https://github.com/inlavigo/gg/compare/3.0.12...3.0.13
[3.0.12]: https://github.com/inlavigo/gg/compare/3.0.11...3.0.12
[3.0.11]: https://github.com/inlavigo/gg/compare/3.0.10...3.0.11
[3.0.10]: https://github.com/inlavigo/gg/compare/3.0.9...3.0.10
[3.0.9]: https://github.com/inlavigo/gg/compare/3.0.8...3.0.9
[3.0.8]: https://github.com/inlavigo/gg/compare/3.0.7...3.0.8
[3.0.7]: https://github.com/inlavigo/gg/compare/3.0.6...3.0.7
[3.0.6]: https://github.com/inlavigo/gg/compare/3.0.5...3.0.6
[3.0.5]: https://github.com/inlavigo/gg/compare/3.0.4...3.0.5
[3.0.4]: https://github.com/inlavigo/gg/compare/3.0.3...3.0.4
[3.0.3]: https://github.com/inlavigo/gg/compare/3.0.2...3.0.3
[3.0.2]: https://github.com/inlavigo/gg/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/inlavigo/gg/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/inlavigo/gg/compare/2.0.5...3.0.0
[2.0.5]: https://github.com/inlavigo/gg/compare/2.0.4...2.0.5
[2.0.4]: https://github.com/inlavigo/gg/compare/2.0.3...2.0.4
[2.0.3]: https://github.com/inlavigo/gg/compare/2.0.2...2.0.3
[2.0.2]: https://github.com/inlavigo/gg/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/inlavigo/gg/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/inlavigo/gg/compare/1.0.16...2.0.0
[1.0.16]: https://github.com/inlavigo/gg/compare/1.0.15...1.0.16
[1.0.15]: https://github.com/inlavigo/gg/compare/1.0.14...1.0.15
[1.0.14]: https://github.com/inlavigo/gg/compare/1.0.12...1.0.14
[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12
