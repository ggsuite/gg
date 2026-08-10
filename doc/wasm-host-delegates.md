# Running gg where there is no `dart:io`

`gg` is a shell around the file system, git, and a terminal. None of those
exist when it is compiled with `dart compile wasm` — the Wasm build ships a
`dart:io` that compiles fine and then throws `UnsupportedError` the moment
you use it.

This document records what exactly breaks, and how gg is wired so an
embedder can supply the missing pieces. The reference embedder is the
[`@tssuite/gg-js`](https://github.com/tssuite/gg-js) npm package, which runs
gg from Node.

## 1. What a Wasm build cannot do

Probed against `dart compile wasm` on Dart 3.12, running under Node 24:

| API                                                             | Wasm  | Note                                            |
| --------------------------------------------------------------- | ----- | ----------------------------------------------- |
| `File(path)`, `Directory(path)`, `Link(path)`, `.path`          | works | Constructors only build a value                 |
| `ProcessResult(…)`, `ProcessSignal.*`, `systemEncoding`         | works |                                                 |
| `File.existsSync`, `readAsString`, `writeAsString`, `list`, …   | **throws** | `Unsupported operation: _Namespace`        |
| `Directory.current`, `Directory.systemTemp`                     | **throws** | `Unsupported operation: _Namespace`        |
| `FileSystemEntity.typeSync`, `isFileSync`, `identicalSync`      | **throws** | `Unsupported operation: _Namespace`        |
| `Platform.operatingSystem`, `.environment`, `.pathSeparator`, … | **throws** | `Unsupported operation: Platform._…`       |
| `stdout`, `stderr`, `stdin`                                     | **throws** | `Unsupported operation: StdIOUtils._…`     |
| `exitCode =`, `exit()`, `pid`, `sleep()`                        | **throws** | `Unsupported operation: ProcessUtils._…`   |
| `Process.run`, `Process.runSync`, `Process.start`               | **throws** | `Unsupported operation: Process.runSync`   |
| `HttpClient`                                                    | **throws** | needs `Platform._version`                  |
| `dart:ffi`                                                      | **absent** | does not even compile                      |

Two consequences shaped the design:

- Types are fine, operations are not. `Directory d` in a signature costs
  nothing; `d.existsSync()` is what fails. The ~900 places in the gg suite
  that merely _mention_ `File` or `Directory` therefore needed no change at
  all.
- `dart:ffi` is a compile-time error, not a runtime one. Anything reachable
  from `main()` that imports it makes the whole build fail — see §4.

## 2. `IOOverrides` does most of the work

`dart:io` ships a supported interception point, and — the part that made
this feasible — **it works under `dart compile wasm`**:

```dart
IOOverrides.global = myOverrides;
```

`IOOverrides` covers `File`, `Directory`, `Link`, `FileSystemEntity`,
`Directory.current`, `Directory.systemTemp`, `stat`, `stdout`, `stderr`,
`stdin` and `exit`. Setting it redirects the whole isolate at once, so
every gg package is served **without a single change at its call sites**.

`lib/src/host/gg_host_io_overrides.dart` implements it on top of the
embedder's callbacks, including `File`, `Directory` and `Link`
implementations that forward each operation. Anything gg does not use
throws `GgHostUnsupportedError` naming the member, rather than failing
obscurely.

## 3. What `IOOverrides` does not cover

Three capabilities have no `dart:io` interception point, so their call
sites were rewritten to go through a delegate. All three delegates live in
`package:gg_process` — the lowest package in the suite with no `gg_*`
dependencies of its own, and the one already responsible for talking to the
host process.

| Capability                       | Delegate                       | Call sites changed |
| -------------------------------- | ------------------------------ | ------------------ |
| `Process.run` / `Process.start`  | `GgProcessDelegate.current`    | 9 in `lib/`, plus `gg_git`'s test helpers |
| `Platform.*`                     | `GgPlatformDelegate.current`   | 6                  |
| `exitCode =`                     | `ggExitCode`                   | 2                  |

Most process execution already went through `GgProcessWrapper` (75 call
sites), which now routes through `GgProcessDelegate.current` — so those
were free.

Two packages needed no change because they already had an escape hatch:
`gg_console_colors` (`ggColorsEnabled`) and `gg_is_github` (`testIsGitHub`).
`GgHost.install` sets both.

## 4. Interactive prompts and `dart:ffi`

`package:interact` draws gg's selection lists and message editors. It
reaches `dart:ffi` through `package:dart_console`, which **fails the Wasm
compile** rather than throwing at runtime — so it had to leave the import
graph entirely.

`gg_one_core/lib/src/tools/prompts.dart` now owns every prompt in the
suite behind `GgPrompts.current`, and picks its default implementation with
a conditional import:

```dart
import 'prompts_interact.dart'
    if (dart.library.js_interop) 'prompts_unsupported.dart' as impl;
```

A native build gets the `package:interact` prompts. A Wasm build gets one
that throws `GgPromptsUnsupportedError`, telling the user which flag to
pass instead — unless the embedder supplies prompts of its own through
`GgHost.prompts`.

## 5. The public surface

Everything above is configured in one place:

```dart
GgHost.install(
  GgHost(
    fileSystem: …,  // GgFileSystemCallbacks
    process: …,     // GgProcessCallbacks
    platform: …,    // GgPlatformCallbacks
    console: …,     // GgConsoleCallbacks
    prompts: …,     // GgPromptCallbacks, optional
  ),
);

final exitCode = await runGg(args: args, ggLog: print);
```

Without an `install` call gg uses `dart:io` directly — which is what the
native `gg` executable does. `GgHost.uninstall()` returns to that state.

The file system callbacks are **synchronous**. gg uses `dart:io`'s `…Sync`
APIs throughout and cannot await a `Future` in the middle of them; Node
answers all of them synchronously via `node:fs`, and the asynchronous
`dart:io` APIs are served from the same callbacks.

Paths handed to a callback are always absolute — `GgHostIoOverrides`
resolves relative ones against `currentDirectory()` first.

## 6. The reference implementation

`GgHostIo` (`lib/src/host/gg_host_io.dart`) is a `GgHost` that answers
every callback with `dart:io`. Installing it must leave gg behaving exactly
as it does with no host at all, which makes it the yardstick for any other
embedder — and `test/host/gg_host_io_test.dart` runs the whole `dart:io`
surface gg uses through it, against a real temp directory.

`test/host/in_memory_host.dart` is the other end of the range: a host
backed by maps, with no `dart:io` anywhere. `test/host/gg_host_test.dart`
runs `runGg` on it. If gg works there, it works on Node.

## 7. Known gaps

- **`Process.start` does not stream.** The callback runs the program to
  completion and the returned `Process` replays its output. Commands that
  write to a started process' stdin (the interactive part of
  `gg one do publish`) do not work through an embedder.
- **`package:http`** still constructs its own client. The publish and
  import flows that call pub.dev, npm and GitHub are therefore untested
  under Wasm.
- **Windows.** `package:path` decides posix-vs-windows from `Uri.base`,
  which a Wasm build reads from `globalThis.location`. `gg-js` points that
  at a `file:` URL, which yields posix. A Windows embedder needs more than
  that.
- **`dart:ffi`** stays unavailable. Anything that needs it must go behind
  a conditional import, the way `prompts.dart` does.
