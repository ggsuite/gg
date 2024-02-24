# GgCheck

GgCheck is a Dart package designed to streamline your development workflow by
offering a suite of pre-commit checks. These include code analysis, linting,
testing, and coverage verification, all complemented by highly optimized and
colorized error messages.

## Key Features

- ✅ **Precise Colorized Error Messages**: Get detailed feedback with error messages that are both precise and easy to understand, enhanced with color for better readability.
- ✅ **Optimized for VSCode**: Error messages are tailored for display in Visual Studio Code, ensuring a seamless integration into your development environment.
- ✅ **Enforces 100% Code Coverage**: Achieve and maintain high-quality code with enforced 100% test coverage for your codebase.
- ✅ **GitHub Action Integration**: Easily integrate GgCheck with GitHub Actions to automate your testing workflow directly within GitHub.

## Preparation

### Create a New Library Project

```bash
dart create -t package hello_world
cd hello_world
```

### Add GgCheck as a Development Dependency

Enhance your project with GgCheck by adding it as a development dependency:

```bash
dart pub add --dev gg_check
```

### Discover GgCheck Commands

Learn about the available commands and their applications:

```bash
dart pub run gg_check -h
```

### Execute All Tests and Checks

```bash
dart run gg_check all
```

### Fix the issues

Address issues identified by GgCheck, aiming for a clean, error-free codebase..

## Ensure Comprehensive Code Coverage

GgCheck demands excellence in testing:

- **Achieve 100% Code Coverage**: Mandatory complete test coverage for all code.
- **Review Short and Precise Coverage Reports**: Analyze uncovered lines and their corresponding tests.
- **Maintain Mandatory Test Files**: Ensure each implementation file has a dedicated test file achieving 100% coverage.

Exclude lines from code that should be excluded from code coverage:

```dart
// coverage:ignore-line
// coverage:ignore-start
// coverage:ignore-end
```

## Set Up GitHub Action for Automated Checks

Automate your testing process by setting up the GgCheck GitHub Action, like here:

<https://github.com/inlavigo/gg_check/blob/main/.github/workflows/pipeline.yaml>

## Contributions

Report your errors and contributions to <https://github.com/inlavigo/gg_check>.
