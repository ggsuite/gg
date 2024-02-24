# GgCheck

Offers pre-commit checks like analyzing, linting, tests and coverage
with highly optimized error messages.

## Features

- ✅ Precise colorized error messages
- ✅ Error messages optimized for Vscode
- ✅ Enforces 100% code coverage
- ✅ Adds a Github action to run the tests on GitHub

## Preparation

### Create a new project

```bash
dart create -t package hello_world
cd hello_world
```

### Add `GgCheck` to your project

```bash
dart pub add --dev gg_check
```

### Print help

```bash
dart pub run gg_check -h
```

### Run all tests

```bash
dart run gg_check all
```

### Fix the issues

`GgCheck` outputs short and precise error messages optimized for Vscode.
Fix all issues until everything is green.

## Code Coverage

- GgCheck enforces 100% code coverage
- Uncovered lines are printed to console together with related tests
- Enforces a test file for each implementation file.
- The test file must cover its impelemntation file by 100%.
- Use `// coverage:ignore-line|start|end` to exclude parts from coverage

## GitHub Action

- To run the checks with GitHub Actions checkout the following file:
  <https://github.com/inlavigo/gg_check/blob/main/.github/workflows/pipeline.yaml>

## Contributions

Report your errors and contributions to <https://github.com/inlavigo/gg_check>.
