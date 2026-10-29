<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# gg checks the Windows developer mode

## Motivation

- gg creates symbolic links, for example while it copies repos into a
  ticket or localizes references.
- On Windows, a normal user may only create symbolic links when the
  developer mode is enabled.
- Without it, gg failed somewhere in the middle of a command, with an error
  that did not say what was missing.
- gg now checks the developer mode up front and tells the user how to
  enable it.

## Strategy

- Check once, at the start of `runGg`, before any command runs.
- Read the setting from the registry instead of probing for a link.
- Stop with a clear hint and exit code 1 when it is disabled.
- Never let a broken check block gg: when the registry cannot be read,
  warn and go on.
- Skip the check wherever it does not apply.

## Reading the developer mode

- New file `lib/src/windows_developer_mode.dart` with
  `checkWindowsDeveloperMode(args:, ggLog:)`.
- It runs `reg query` on
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock`, value
  `AllowDevelopmentWithoutDevLicense`.
- `0x1` means enabled. `0x0` or a missing value (reg exits with 1) means
  disabled — a fresh Windows has no value at all.
- reg runs through `ggRunProcess`, the platform comes from `ggPlatform`,
  so tests swap both delegates instead of using new parameters.

## The hint

- Disabled, gg prints in red:

  ```
  gg needs the Windows developer mode, it creates symbolic links.
  Enable it: Settings → System → For developers → Developer Mode
  (or run: start ms-settings:developers), then run gg again.
  ```

- The command is colored with `cCmd`, like the other gg hints.
- Unreadable registry or unknown output: a yellow warning, gg continues.

## When the check is skipped

- Off Windows.
- Under an installed `GgHost`: the embedder creates the links itself.
- On GitHub Actions (`isGitHub`): the runners are elevated.
- For calls that only ask for the usage: no command, `help`, `--help`,
  `-h`, and `--version`.

## Usage-only calls in one place

- New `isUsageOnly(args)` in `project_detector.dart`.
- `checkArgsForProjectMode` uses it too, so `gg do commit --help` now
  prints the usage outside a workspace instead of asking for one.

## Other changes

- README: the installation section names the developer mode.
- New `index.jsonc` describing the repo.

## Open Points

- Users who can create links without the developer mode (elevated shell,
  group policy, other CI systems than GitHub Actions) are blocked too.
- Each gg call on Windows starts one `reg` process (about 20-30 ms).
