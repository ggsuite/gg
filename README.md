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

`gg` detects where you run it:

- Inside a **gg ticket workspace** (a directory tree containing
  `.master/` or `tickets/`) → `gg <command>` runs `gg_multi` by default.
- Inside a **standalone Dart or TypeScript project** (a directory tree
  with `pubspec.yaml`, `package.json` or `tsconfig.json`) → `gg` prints
  a message asking you to use `gg one <command> …` explicitly.

## Installation

```bash
dart pub global activate gg
```

After installation the `gg` executable is available globally.

## Command Overview

```
gg
├── run                    Serve the gg_multi web UI at http://localhost:8084
├── one  <subcommand>      Single-repo mode (gg_one)
├── can  <commit|push|publish|review>
├── did  <commit|push>
├── do   <commit|push|review|cancel-review|publish|claude|code|
│         create|init|add|add-deps|rm|execute|…>
└── ls   <repos|organizations|deps|tickets>
```

`can`, `did`, `do` and `ls` are the `gg_multi` commands, registered
directly at the root: inside a gg ticket workspace `gg do commit`
runs `gg_multi`'s `do commit`. In a standalone project these commands
abort with a message asking you to run `gg one <cmd> …` instead, and
outside of any recognized project `gg` aborts with a hint explaining
both options. (`gg multi <cmd>` still works as a hidden alias for the
root commands.)

## When to use `gg one`

Use `gg one` when you are working in **exactly one** Dart or
TypeScript project — for example a freshly cloned package, a library
you maintain on its own, or a repo that is not part of a ticket
workspace.

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

`gg one …` is always explicit: in a standalone project a plain
`gg can commit` or `gg do push` does not run anything but prints a
message asking you to use `gg one` instead.
This also works inside a ticket workspace when you want to run
`gg_one` against a single repo (where `gg can`/`gg do` runs
`gg multi`).

## Workspace commands (`gg_multi`)

Inside a gg ticket workspace the `gg_multi` commands drive operations
across all repos of a ticket — they run by default, directly at the
root. See the `gg_multi` README and `handbook.md` for the full
command surface; the most important ones are:

| Command                    | Purpose                                             |
| -------------------------- | --------------------------------------------------- |
| `gg do init`               | initialise the master workspace                     |
| `gg do add <target>`       | add a repo or a whole org to the workspace / ticket |
| `gg do create ticket <id>` | create `tickets/<id>/` with a `.ticket` file        |
| `gg do code`               | open the ticket in VS Code                          |
| `gg can commit`            | check whether all ticket repos can commit           |
| `gg do commit -m "…"`      | commit in every ticket repo in dependency order     |
| `gg can push` / `do push`  | check / push every ticket repo                      |
| `gg do review`             | run the full review pipeline across the ticket      |
| `gg do publish`            | publish every publishable package of the ticket     |
| `gg ls repos`              | list repos in the master workspace                  |
| `gg do claude`             | generate an aggregated `CLAUDE.md` for the ticket   |

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

`gg do init` and `gg do add` are `gg_multi` workspace commands and
run directly at the root.

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

#### Non-interactive publish via `--config`

Both backends understand `--config <path>` for `do publish`. Pass a
`.gg-publish.json` file to predeclare merge messages and version
increments so the release runs prompt-free (handy in CI):

```bash
gg do publish --config .gg-publish.json
```

Minimal schema (top-level fields apply to every repo; the optional
`repos` block lets you override per repo in workspace mode):

```jsonc
{
  "version_increment": "patch",          // "patch" | "minor" | "major"
  "merge_message": "Default merge message",
  "repos": {
    "app_core": {                        // optional per-repo override
      "version_increment": "minor",
      "merge_message": "app_core: new public API"
    }
  }
}
```

`gg` looks for `<configArg>` as given (relative to the current
directory, or absolute), then under the ticket directory in workspace
mode, or under `<repo>/.gg/` in single-repo mode. A missing required
field aborts the run — no silent fall-back to a prompt.

See the [`gg_multi`](https://github.com/ggsuite/gg_multi#non-interactive-publish-via---config)
and [`gg_one`](https://github.com/ggsuite/gg_one#publish-a-single-package-with-gg-one-do-publish)
READMEs for the full schema and lookup rules.

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
```

`gg` and `gg -h` list all `gg_multi` commands plus `gg one` and
`gg run`.

## License

`gg` is licensed under the terms specified in the `LICENSE` file.
