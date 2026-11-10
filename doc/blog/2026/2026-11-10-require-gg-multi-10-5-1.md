<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Require gg_multi 10.5.1

## Motivation

- gg takes its workspace commands from gg_multi, which re-exports its
  sub-packages in one library.
- Between gg_multi_do_publish 4.7.1 (6 November) and the fix (10
  November) two of those sub-packages each declared a typedef
  `ReadSettings`. gg_multi then failed to compile, and with it gg:
  `Failed to build gg:gg: … 'ReadSettings' is exported from both …`
- gg 17.7.0 allows `gg_multi: ^10.4.0`, and gg_multi 10.5.0 still admits
  the broken sub-package versions. A fresh resolve is fine, because it
  picks the newest versions, but a resolve that keeps an older lock file
  is not.
- gg_multi 10.5.1 admits only the fixed sub-packages. Requiring it makes
  every resolution of gg compile.

## Strategy

- Raise the gg_multi constraint to the release that pins the fixed
  sub-packages
- Change no code
- Check that gg resolves to the fixed versions and passes its checks

## Implementation

- `pubspec.yaml`: `gg_multi: ^10.4.0` becomes `gg_multi: ^10.5.1`
- With it, gg resolves gg_multi_core 4.18.0, gg_multi_do_publish 4.7.2
  and gg_multi_workspace 4.24.2
- `dart analyze` is clean and `gg can commit` passes

## Dependency updates

- gg_multi 10.5.1: requires gg_multi_core `^4.18.0`, gg_multi_commit
  `^4.9.2`, gg_multi_do_publish `^4.7.2` and gg_multi_workspace
  `^4.24.2`. `ReadSettings` is declared once, in gg_multi_core
- `gg_one`, `gg_process`, `gg_is_github`, `gg_create_repo` and
  `dna_ggsuite`: tightened to their current versions by the regular
  dependency upgrade

## Result

- A gg installed from this version on cannot resolve the sub-packages
  that clash
- Released as a patch version

## Open Points

- An installation that already holds the broken versions keeps them:
  gg rebuilds from the lock file it was activated with. Run
  `dart pub global activate gg` once to resolve it again.
