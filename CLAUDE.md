# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`gg` is a Dart CLI tool (`gg` executable) for managing multi-repository ticket workspaces. It orchestrates cross-repo operations — committing, pushing, reviewing, publishing — across all Dart/Flutter packages in a ticket.

This repository (`gg`) depends on a sibling package `gg_multi` at `../gg_multi`. Both are typically open together in the `feat-do-claude.code-workspace`.

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
dart run bin/gg.dart run         # start web server at http://localhost:8084
```

## Architecture

### Package Structure

`gg` is a thin CLI shell. All business logic lives in `gg_multi` (`../gg_multi`).

```
bin/gg.dart          → entry point: main() → runGg()
lib/src/commands/
  gg.dart        → root Command; registers GgRun, GgOne, and all GgMulti subcommands
  gg_one.dart    → `gg one` — re-exposes all `gg` subcommands under the gg namespace
  gg_run.dart    → `gg run` — HTTP server (port 8084) serving the pre-built gg_multi_ui/ Flutter web app
gg_multi_ui/           → pre-built Flutter web app (static assets, not a source package)
```

### Command Hierarchy

```
gg
├── run          (GgRun)    — serves gg_multi_ui at localhost:8084
├── one          (GgOne)    — all `gg` subcommands
├── ls           (ListCommand)  — list organizations, repos, deps, tickets
├── can          (Can)          — can commit / push / publish / review
├── did          (Did)          — did commit / push
└── do           (Do)           — do commit / push / publish / review / cancel-review
                                   execute / install-git-hooks / claude
                                   add / add-deps / code / create / init / rm
```

`GgMulti` (from `gg_multi`) contributes `ls`, `can`, `did`, and `do` subcommands by iterating over its `.subcommands.values`.

### gg_multi

The sibling package contains the actual command implementations organized as:

- `lib/src/commands/` — command classes (`can/`, `did/`, `do/`, `list/`)
- `lib/src/backend/` — shared utilities (git, pub.dev, workspace detection, organizations, repositories)

Key backend concepts:
- **Organization** — a GitHub org or group of repos
- **Repository** — a single Dart/Flutter git repo within a ticket workspace
- **WorkspaceUtils** — detects ticket boundaries by walking the directory tree
- **SortedProcessingList** — returns repos in dependency order for safe cross-repo operations

### `gg do claude`

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
