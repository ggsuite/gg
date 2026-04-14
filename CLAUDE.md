# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`kd` is a Dart CLI tool (`kd` executable) for managing multi-repository ticket workspaces. It orchestrates cross-repo operations — committing, pushing, reviewing, publishing — across all Dart/Flutter packages in a ticket.

This repository (`kd`) depends on a sibling package `kidney_core` at `../kidney_core`. Both are typically open together in the `feat-do-claude.code-workspace`.

## Commands

### Development

```bash
dart pub get                              # install dependencies
dart analyze                             # static analysis
dart format .                            # format all files
dart test                                # run all tests
dart test test/path/to/file_test.dart    # run a single test file
```

### Committing and Pushing

Always use `gg` commands (never plain `git commit`/`git push`):

```bash
gg can commit                    # run all checks (analyze + format + tests)
gg do commit -m <message>        # commit after checks pass
gg do push                       # push after checks pass
```

### Running the UI

```bash
dart run bin/kd.dart run         # start web server at http://localhost:8084
```

## Architecture

### Package Structure

`kd` is a thin CLI shell. All business logic lives in `kidney_core` (`../kidney_core`).

```
bin/kd.dart          → entry point: main() → runKidney()
lib/src/commands/
  kidney.dart        → root Command; registers KidneyRun, KidneyOne, and all KidneyCore subcommands
  kidney_one.dart    → `kd one` — re-exposes all `gg` subcommands under the kd namespace
  kidney_run.dart    → `kd run` — HTTP server (port 8084) serving the pre-built kidney_ui/ Flutter web app
kidney_ui/           → pre-built Flutter web app (static assets, not a source package)
```

### Command Hierarchy

```
kd
├── run          (KidneyRun)    — serves kidney_ui at localhost:8084
├── one          (KidneyOne)    — all `gg` subcommands
├── ls           (ListCommand)  — list organizations, repos, deps, tickets
├── can          (Can)          — can commit / push / publish / review
├── did          (Did)          — did commit / push
└── do           (Do)           — do commit / push / publish / review / cancel-review
                                   execute / install-git-hooks / claude
                                   add / add-deps / code / create / init / rm
```

`KidneyCore` (from `kidney_core`) contributes `ls`, `can`, `did`, and `do` subcommands by iterating over its `.subcommands.values`.

### kidney_core

The sibling package contains the actual command implementations organized as:

- `lib/src/commands/` — command classes (`can/`, `did/`, `do/`, `list/`)
- `lib/src/backend/` — shared utilities (git, pub.dev, workspace detection, organizations, repositories)

Key backend concepts:
- **Organization** — a GitHub org or group of repos
- **Repository** — a single Dart/Flutter git repo within a ticket workspace
- **WorkspaceUtils** — detects ticket boundaries by walking the directory tree
- **SortedProcessingList** — returns repos in dependency order for safe cross-repo operations

### `kd do claude`

Generates a ticket-level `CLAUDE.md` by reading each repo's own `CLAUDE.md` in dependency order and concatenating them. Requires every repo to already have a `CLAUDE.md` (run `/init` in each repo first).

## Code Standards

- **Line length**: 80 characters maximum
- **Quotes**: Single quotes (`prefer_single_quotes`)
- **Trailing commas**: Required in parameter/argument lists
- **Return types**: Always declared explicitly
- **Public API docs**: All public members require dartdoc comments
- **Strict analyzer**: `strict-casts`, `strict-inference`, `strict-raw-types` all enabled
- **Test coverage**: 100% required. Use `// coverage:ignore-line` / `// coverage:ignore-start` / `// coverage:ignore-end` only when truly necessary.

Each source file in `lib/src/` must have a corresponding test file in `test/` at the same relative path.
