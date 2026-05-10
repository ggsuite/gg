# gg

Use gg to apply shell commands to all dart packages in your directory:

```
gg . --apply --verbose ls
```

## Install

```bash
 dart pub global activate gg
```

## Examples

| Gg part    | Command part   | Explenation                      |
| -------------- | -------------- | -------------------------------- |
| `gg . -av` | `ls`           | Executes ls in all packages      |
| `gg . -a`  | `flutter test` | Run the tests in all directories |
| `gg .`     | `ls`           | Start a dry run                  |

## Show help

```bash
gg
```

## Run tests on all packages

Change into your dev directory containing dart packages.

Execute the following command:

```bash
gg . -a flutter test
```

## Show the directory contents

To see the folder contents, add the `-v` option and call `ls`:

```bash
gg . -av ls
```

## Do a dry-run

Remove the `-a` option, to perform a dry run of the desired command:

```bash
gg . -a ls
```

## All options

| Long        | Short | Explenation                                 |
| ----------- | ----- | ------------------------------------------- |
| `--apply`   | `-a`  | Without that option only a dry-run is done. |
| `--verbose` | `-v`  | Prints CLI output of the commands           |
