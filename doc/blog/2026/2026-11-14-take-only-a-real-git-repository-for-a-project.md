<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Take only a real git repository for a project

## Motivation

- `gg` looks at the folder it is started in before it runs a command. In
  a ticket workspace `gg <command>` works on all repos of the ticket; in
  a standalone project it asks for `gg one <command>`; anywhere else it
  points to `gg do init workspace`
- A standalone project is a folder with a `pubspec.yaml`, a
  `package.json` or a `tsconfig.json` in it or above it — or a git
  repository
- For the repository, any file or folder called `.git` was enough. A
  folder of that name that is no repository at all turned every folder
  below it into a standalone project
- That happens on real machines: an interrupted clone or another tool
  leaves a `.git` folder with nothing but `objects` in it. One of these
  in a home directory made `gg` answer »This is a standalone project«
  everywhere in that home directory, where »Not a workspace« was the
  truth
- The tests of this repo work in the temp folder, which lies in the home
  directory on Windows. Two of them expect »no project« there and failed
  on such a machine, although nothing was wrong with the code under test

## Strategy

- Ask what makes a folder a git repository, not what it is called
- Keep worktrees and submodules, whose `.git` is a file
- Make the tests build repositories the same way a clone looks, so they
  no longer depend on what lies above the temp folder

## What counts as a repository

- `ProjectDetector._isRepository(dir)` answers for one folder:
  - a `.git` **folder** counts when it holds a `HEAD` — `git init` and
    `git clone` write that file first, and no repository is without it
  - a `.git` **file** counts as before: a worktree and a submodule keep
    their repository elsewhere and name it in that file
- A `.git` folder without `HEAD` is skipped, and the search goes on in
  the folder above it
- Nothing else changed: workspace markers (`.ocean`, the legacy
  `.master`, `tickets`) still win over everything, and the manifests are
  still found without a repository

## One way to walk up

- `_walkUp(startPath, isFound)` walks from a folder to the root of the
  drive and asks `isFound` for each folder on the way
- `_walkUpFor(startPath, markers, isDirectory:)` — the search for a
  marker file or a marker folder — is now built on it, and so is the
  search for a repository
- The former third mode of `_walkUpFor`, »a file or a folder«, is gone:
  only the repository search used it

## Tests

- `initRepo(dir)` creates `.git/HEAD`, and the tests that need a
  repository use it instead of an empty `.git` folder
- A new test puts a `.git` folder with only `objects` above the working
  directory and expects »no project«
- The two tests that expect »no project« in an empty temp folder pass
  again on a machine with a stray `.git` in the home directory

## Open Points

- Whether the repository that was found is the one the working directory
  belongs to is not checked yet. A real repository far above — dotfiles
  kept in a home directory — still makes every folder below it a
  standalone project, and the two tests fail on such a machine. Two ways
  are open: take a `.git` only in the folder gg is started in, or ask
  git whether that folder is part of the repository
- A `.git` file is trusted without a look at the folder it names
- A stray `.git` folder is still on the disk. `gg` only stops taking it
  for a repository; git itself may still stumble over it
