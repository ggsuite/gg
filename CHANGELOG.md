# Changelog

## Unreleased

### Added

- Add helix as »gg dna«

## 17.1.1 - 2026-08-15

### Changed

- Flutter projecs fail on publish

## 17.1.0 - 2026-08-14

### Changed

- Rework copyright headers

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.
- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

## 17.0.0 - 2026-08-13

## 16.1.1 - 2026-08-11

### Added

- `GgHost` — the one place gg's access to the outside world is configured.
An embedder supplies file system, process, platform, console and prompt
callbacks, and gg routes everything through them. See
`doc/wasm-host-delegates.md`.
- `GgHostIo`, a `GgHost` answering every callback with `dart:io`, as the
reference implementation an embedder is measured against.
- `runGg` moved from `bin/gg.dart` into `lib/src/run_gg.dart` so embedders
can call it, and now returns the exit code instead of setting it.

### Changed

- "First javascript implementation"
- Fix shell changes

## 16.1.0 - 2026-08-10

### Changed

- Refactor commit messages, version increment

## 16.0.0 - 2026-08-10

## 15.3.1 - 2026-08-10

### Fixed

- Various log and color fixes across the gg command output
- Fix org-url repo add, code-workspace upkeep on rm and the auto-merge PR hint
- Various fixes

## 15.3.0 - 2026-08-10

### Changed

- Merge origin/main

## 15.2.0 - 2026-08-09

## 15.1.0 - 2026-08-08

## 15.0.0 - 2026-08-08

## 14.2.0 - 2026-08-04

### Changed

- Use overrides in package.json

## 14.1.1 - 2026-08-04

### Changed

- Improve push and publish workflow

## 14.1.0 - 2026-08-04

### Changed

- Rename .master to .ocean with automatic migration at next start
- Rename ocean workspace -> ocean
- Update version

## 14.0.5 - 2026-08-04

### Changed

- Finetune command line output
- Update dependencies

## 14.0.4 - 2026-08-03

### Changed

- Improve review workflow

## 14.0.3 - 2026-08-03

### Changed

- dart pub upgrade --major-versions --tighten
- use the semantic colors of gg_console_colors: cAction for instructions,
cWarn for warnings, cDetail for progress, cCmd/cPath inside a message
- wrap every exception text in cError
- assert the plain text in the tests, not the escape codes (rmC)
- reword the gg root description to "Work on tickets across many repos"
- replace do cancel-review with do review --abort
- move ls under do
- rename gg one description to "Work in standalone repos"
- Rework CLI texts
- Rework console colors
- Improve cli log and colors

### Removed

- remove do add-deps command
- Remove unused CLI commands

## 14.0.2 - 2026-08-02

## 14.0.1 - 2026-07-31

### Changed

- Require minimum gg version

## 14.0.0 - 2026-07-31

### Changed

- Do not publish unchanged packages

## 13.0.1 - 2026-07-31

### Changed

- Rename exec into maintain

## 13.0.0 - 2026-07-31

## 12.1.6 - 2026-07-30

### Changed

- Improve "gg do init" message

## 12.1.5 - 2026-07-30

### Changed

- Show a clear message when gg is called in non git or non ticket spaces

## 12.1.4 - 2026-07-30

### Fixed

- Fix: 'gg do init' does not work

## 12.1.3 - 2026-07-30

### Fixed

- Fix "gg do init" was not forwarded to "gg multi do init"

## 12.1.2 - 2026-07-30

### Fixed

- Fix: Empty repos were not treated as stand alone projects

## 12.1.1 - 2026-07-29

### Removed

- Remove dependencies that are no longer needed: gg_local_package_dependencies,
gg_process, gg_project_root, gg_status_printer, mocktail, pub_semver,
pubspec_parse, yaml_edit, fake_async and gg_capture_print
- Remove the orphaned `test/test_helpers/` directory, which was no longer
referenced by any test
- Remove the bundled `gg_multi_ui/` web assets, which were only served by
`gg run`
- Remove run command because it is not used

## 12.1.0 - 2026-07-29

### Changed

- gg_multi: changed references to git

## 12.0.2 - 2026-07-29

### Changed

- gg_multi: changed references to git

### Removed

- Remove git hooks functionality completely because merging is done via merge requests

## 12.0.1 - 2026-07-29

### Fixed

- Fix: If an argument was equal command, the command was not executed

## 12.0.0 - 2026-07-29

### Changed

- gg now runs gg multi by default inside ticket workspaces: all gg multi
commands are available at the root and shown in gg --help alongside gg one;
standalone projects, including repos checked out in .master, are no longer
auto-routed but get a colored hint to run gg one <command> instead

## 11.0.1 - 2026-07-25

### Fixed

- IMPORTANT FIX: Previous version removed tag_patterns on publishing

## 11.0.0 - 2026-07-22

### Changed

- Update publish docs: the final merge goes through an auto-merge squash pull
request by default
- gg_multi: changed references to git

## 10.4.2 - 2026-07-20

### Changed

- gg_multi: changed references to git

### Fixed

- Ignore `.gg/*` instead of the whole `.gg` directory, so `.gg/.gg.json` and
`.gg/.ticket.json` stay trackable

## 10.4.1 - 2026-07-20

### Changed

- gg_multi: changed references to git

## 10.4.0 - 2026-07-15

### Changed

- Deliver gg_one 10.0.0 (do configure-publish + step-based resumable
publishing) and gg_multi 5.7.0 (two-level --continue resume)

## 10.3.0 - 2026-07-06

### Changed

- gg_multi: changed references to git

## 10.2.1 - 2026-06-26

### Changed

- gg_multi: changed references to git

## 10.2.0 - 2026-06-19

### Changed

- gg_multi: changed references to git

## 10.1.0 - 2026-06-09

### Changed

- gg_multi: changed references to git
- style: apply grace-cloud comment + 80-char limits across ticket
- gg_multi: changed references to git

## 10.0.0 - 2026-06-08

### Changed

- gg_multi: changed references to git
- gg_multi: changed references to git

## 9.4.0 - 2026-05-20

### Changed

- gg_multi: changed references to git

## 9.3.0 - 2026-05-19

### Changed

- gg_multi: changed references to git

## 9.2.1 - 2026-05-19

### Changed

- gg_multi: changed references to git

## 9.2.0 - 2026-05-17

### Changed

- documentation
- gg_multi: changed references to git

## 9.1.0 - 2026-05-12

### Changed

- gg_multi: changed references to git

## 9.0.1 - 2026-05-11

### Changed

- gg_multi: changed references to git
- Gg Multi: changed references to pub.dev
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

## 3.1.0 - 2026-05-04

### Changed

- Bump gg dependency to 7.0.5

## 3.0.4 - 2026-04-29

## 3.0.3 - 2026-04-28

## 3.0.2 - 2026-04-28

## 3.0.1 - 2026-04-24

## 3.0.0 - 2026-04-23

## 2.6.1 - 2026-04-15

## 2.6.0 - 2026-04-14

## 2.5.2 - 2026-04-13

## 2.5.1 - 2026-04-08

## 2.5.0 - 2026-04-08

### Changed

- kidney: changed references to local

## 2.4.0 - 2026-04-07

## 2.3.0 - 2026-04-01

## 2.2.2 - 2026-03-31

## 2.2.1 - 2026-03-30

## 2.2.0 - 2026-03-30

## 2.1.2 - 2026-03-29

## 2.1.1 - 2026-03-27

## 2.1.0 - 2026-03-27

### Removed

- remove publish_to:none

## 2.0.0 - 2026-03-26

### Changed

- kidney: changed references to path
- kidney: changed references to git
- Kidney: changed references to pub.dev

### Fixed

- small fixes in tests and version upgrades

## 1.1.0 - 2026-03-26

## 1.0.0 - 2026-03-25

### Changed

- commit
