# gg

`gg` is the unified Dart CLI for Dart and Flutter development at every
scale — from running pre-commit checks in a single package to
orchestrating commits, pushes, reviews and publishes across all
repositories of a ticket.

It is a thin CLI shell that combines two backend packages:

| Package    | Scope                          | Purpose                                                  |
| ---------- | ------------------------------ | -------------------------------------------------------- |
| `gg_one`   | a single Dart/TypeScript repo  | pre-commit checks (analyze, format, test, coverage, …)   |
| `gg_multi` | a multi-repo ticket workspace  | run commands across all repos of a ticket in dep order   |

`gg` automatically chooses the right backend based on where you run it:

- Inside a **gg workspace** (a directory tree containing `.master/` or
  `tickets/`) → routed to `gg_multi`.
- Inside a **single Dart or TypeScript project** (a directory tree with
  `pubspec.yaml`, `package.json` or `tsconfig.json`) → routed to `gg_one`.

## Installation

```bash
dart pub global activate gg
```

After installation the `gg` executable is available globally.

## Command Overview

```
gg
├── run                    Serve the gg_multi web UI at http://localhost:8084
├── one  <subcommand>      Force single-repo mode (gg_one)
├── multi <subcommand>     Force workspace mode (gg_multi)
├── can  <commit|push|publish|review>
├── did  <commit|push>
├── do   <commit|push|review|cancel-review|publish|claude|code|
│         create|init|add|add-deps|rm|execute|install-git-hooks|…>
└── ls   <repos|organizations|deps|tickets>
```

`can`, `did` and `do` are **shared**: `gg` rewrites them to
`gg multi …` or `gg one …` depending on the detected project mode. If
the current directory is neither, `gg` aborts with a message telling
you to call `gg one <cmd>` or `gg multi <cmd>` explicitly.

## When to use `gg one`

Use `gg one` (or rely on auto-detection inside a single package) when
you are working in **exactly one** Dart or TypeScript project — for
example a freshly cloned package, a library you maintain on its own,
or a repo that is not part of a ticket workspace.

`gg one` is a re-export of the `gg_one` package and offers the
following subcommands:

| Command                    | Purpose                                                            |
| -------------------------- | ------------------------------------------------------------------ |
| `gg one check analyze`     | static analysis                                                    |
| `gg one check format`      | formatting check                                                   |
| `gg one check`             | run the full local check pipeline (analyze + format + tests + …)   |
| `gg one can commit`        | verify the repo is ready to commit                                 |
| `gg one do commit -m "…"`  | commit after checks pass                                           |
| `gg one can push`          | verify the repo is ready to push                                   |
| `gg one do push`           | push after checks pass                                             |
| `gg one did commit`        | report what was committed since the last reference state           |
| `gg one info`              | print project metadata gg_one detected                             |

In a single-package directory you usually do not need to type
`gg one …` explicitly — `gg can commit` and `gg do push` are
auto-routed to `gg one`. The explicit form is only needed when
- you want to run `gg_one` against a single repo that **is** inside a
  workspace (where `gg can`/`gg do` would otherwise pick `gg multi`),
- you want to be unambiguous in scripts and CI pipelines, or
- you are outside any project and need to point gg at one explicitly.

## When to use `gg multi`

`gg multi` (or auto-detected workspace mode) drives operations across
all repos of a ticket. See the `gg_multi` README and `handbook.md`
for the full command surface; the most important ones are:

| Command                          | Purpose                                                     |
| -------------------------------- | ----------------------------------------------------------- |
| `gg multi do init`               | initialise the master workspace                             |
| `gg multi do add <target>`       | add a repo or a whole org to the workspace / ticket         |
| `gg multi do create ticket <id>` | create `tickets/<id>/` with a `.ticket` file                |
| `gg multi do code`               | open the ticket in VS Code                                  |
| `gg multi can commit`            | check whether all ticket repos can commit                   |
| `gg multi do commit -m "…"`      | commit in every ticket repo in dependency order             |
| `gg multi can push` / `do push`  | check / push every ticket repo                              |
| `gg multi do review`             | run the full review pipeline across the ticket              |
| `gg multi do publish`            | publish every publishable package of the ticket             |
| `gg multi ls repos`              | list repos in the master workspace                          |
| `gg multi do claude`             | generate an aggregated `CLAUDE.md` for the ticket           |

## Step-by-step: working on a ticket end-to-end

The following walkthrough covers the typical lifecycle of a feature
ticket from setup to publish. All commands assume `gg` is installed
globally.

### 0. One-time project setup

```bash
mkdir my_project
cd my_project
gg do init                               # initialise master workspace
gg do add https://github.com/my-org      # add all repos of an org
```

`gg do init` and `gg do add` are workspace commands, so they are
auto-routed to `gg multi`.

### 1. Create a ticket workspace

```bash
cd my_project
gg do create ticket PROJ-123 -m 'Simplify login flow'
cd tickets/PROJ-123
```

This creates `tickets/PROJ-123/` and writes a `.ticket` file with the
ticket id and description.

### 2. Add the repos you need

```bash
gg do add app_core ui_core
```

Local dependencies are added automatically, and packages are
localised inside the ticket so that intra-workspace edits resolve to
local paths.

### 3. Open the ticket in VS Code (optional)

```bash
gg do code
```

### 4. Develop, run checks, iterate

Inside any individual repo of the ticket you can fall back to
single-repo checks via `gg one`:

```bash
cd app_core
gg one check                    # full local pipeline for app_core only
```

### 5. Commit across all ticket repos

```bash
cd ../..                        # back to tickets/PROJ-123
gg can commit                   # verify every repo is commit-ready
gg do commit -m 'Simplify login flow'
```

`gg can commit` runs the full check pipeline (analyze, format, tests)
in every repo in dependency order and aborts on the first failure.

### 6. Push

```bash
gg can push
gg do push
```

### 7. Review

```bash
gg do review
```

`do review` unlocalises references, re-localises them as Git refs,
runs `pub upgrade`, commits and pushes — bringing every repo into a
consistent state ready for merge.

If you need to keep working after starting a review:

```bash
gg do cancel-review
```

### 8. Publish (when approved)

```bash
gg can publish
gg do publish
```

Publish should be triggered manually by a human after review approval.

### 9. Generate an aggregated CLAUDE.md (optional)

```bash
gg do claude
```

Concatenates each repo's `CLAUDE.md` (in dependency order) into a
single `CLAUDE.md` at the ticket root so Claude Code has full
workspace context.

## Running the UI

```bash
gg run                          # serves http://localhost:8084
```

`gg run` starts an HTTP server that serves the pre-built `gg_multi`
Flutter web UI bundled with the package.

## Getting help

Every command supports `-h` / `--help`:

```bash
gg -h
gg do -h
gg do commit -h
gg one -h
gg multi -h
```

## License

`gg` is licensed under the terms specified in the `LICENSE` file.
