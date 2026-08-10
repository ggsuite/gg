// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_is_github/gg_is_github.dart';
import 'package:gg_one/gg_one.dart' show GgPrompts;
import 'package:gg_process/gg_process.dart';

import 'gg_host_callbacks.dart';
import 'gg_host_io_overrides.dart';

/// The one place where gg's access to the outside world is configured.
///
/// gg is a shell around the file system, git and other command line tools.
/// `dart compile wasm` produces a `dart:io` whose file, process, platform
/// and console APIs all throw `UnsupportedError` at runtime, so a gg
/// compiled to WebAssembly cannot do any of that on its own.
///
/// [GgHost] closes that gap. An embedder — the `@tssuite/gg-js` npm package
/// is the reference one — hands gg a set of callbacks, and from then on
/// every file read, every `git` invocation and every line printed goes
/// through them:
///
/// ```dart
/// GgHost.install(
///   GgHost(
///     fileSystem: myFileSystemCallbacks,
///     process: myProcessCallbacks,
///     platform: myPlatformCallbacks,
///     console: myConsoleCallbacks,
///   ),
/// );
/// await runGg(args: args, ggLog: print);
/// ```
///
/// Nothing else in the gg suite needs to know an embedder exists:
/// [install] redirects `dart:io` through `IOOverrides.global` and the
/// process and platform delegates of `package:gg_process`, both of which
/// every gg package already routes through.
///
/// Without an [install] call gg keeps using `dart:io` directly, which is
/// what the native `gg` executable does.
class GgHost {
  /// Bundles the callbacks gg needs from its embedder.
  const GgHost({
    required this.fileSystem,
    required this.process,
    required this.platform,
    required this.console,
    this.prompts,
    this.onExit,
  });

  /// Reads and writes files and directories.
  final GgFileSystemCallbacks fileSystem;

  /// Runs git and the other command line tools gg drives.
  final GgProcessCallbacks process;

  /// Answers questions about the machine and the process.
  final GgPlatformCallbacks platform;

  /// Writes to the terminal and reads from it.
  final GgConsoleCallbacks console;

  /// Draws the interactive prompts, or `null` when the embedder has none.
  ///
  /// Without them gg refuses the interactive commands with a message
  /// naming the flag to pass instead — it never hangs waiting for input
  /// nobody can give.
  final GgPromptCallbacks? prompts;

  /// Called when gg calls `exit(code)`. Must not return.
  ///
  /// Defaults to recording the code via [GgPlatformCallbacks.setExitCode]
  /// and throwing a [GgExitException], which [runGg] turns back into an
  /// exit code.
  final Never Function(int code)? onExit;

  // ...........................................................................
  /// Installs [host] and routes all of gg through it.
  ///
  /// Replaces a previously installed host. Call [uninstall] to go back to
  /// plain `dart:io`.
  static void install(GgHost host) {
    _installed = host;

    IOOverrides.global = GgHostIoOverrides(
      fileSystem: host.fileSystem,
      console: host.console,
      onExit: host.onExit ?? _defaultExit,
    );

    GgProcessDelegate.current = _HostProcessDelegate(host.process);
    GgPlatformDelegate.current = _HostPlatformDelegate(host.platform);

    final prompts = host.prompts;
    GgPrompts.current = prompts == null ? null : _HostPrompts(prompts);

    // Both packages read `Platform.environment` lazily and both offer an
    // override that keeps them from ever touching `dart:io`.
    ggColorsEnabled =
        host.console.supportsAnsiEscapes() &&
        !_colorsOff(host.platform.environment());
    testIsGitHub = host.platform.environment().containsKey('GITHUB_ACTIONS');
  }

  /// Removes an installed host — gg talks to `dart:io` again.
  static void uninstall() {
    _installed = null;
    IOOverrides.global = null;
    GgProcessDelegate.current = null;
    GgPlatformDelegate.current = null;
    ggColorsEnabled = null;
    testIsGitHub = null;
    GgPrompts.current = null;
  }

  /// The host currently installed, or `null` when gg uses `dart:io`.
  static GgHost? get installed => _installed;

  static GgHost? _installed;

  static bool _colorsOff(Map<String, String> env) =>
      env.containsKey('NO_COLOR') || env['TERM'] == 'dumb';

  static Never _defaultExit(int code) {
    GgPlatformDelegate.current.exitCode = code;
    throw GgExitException(code);
  }
}

// .............................................................................
/// Thrown instead of terminating the process when gg calls `exit(code)`
/// while a [GgHost] is installed.
class GgExitException implements Exception {
  /// Default constructor
  const GgExitException(this.code);

  /// The exit code gg asked for.
  final int code;

  @override
  String toString() => 'gg exited with code $code';
}

// #############################################################################
/// Runs processes through [GgProcessCallbacks].
class _HostProcessDelegate extends GgProcessDelegate {
  _HostProcessDelegate(this._callbacks);

  final GgProcessCallbacks _callbacks;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) async => ggProcessResultFrom(
    await _callbacks.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    ),
  );

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final start = _callbacks.start;
    if (start == null) {
      // No streaming host: run the program to completion and replay what it
      // wrote. Enough for a caller that reads the output at the end.
      return _CompletedProcess(
        await _callbacks.run(
          executable,
          arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          runInShell: runInShell,
        ),
      );
    }

    return _StreamingProcess(
      await start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        detached:
            mode == ProcessStartMode.detached ||
            mode == ProcessStartMode.detachedWithStdio,
      ),
    );
  }
}

// #############################################################################
/// A [Process] fed by a [GgStartedProcess] while the program runs.
///
/// The two stream controllers are single-subscription, so anything the
/// program writes before gg gets around to listening is buffered rather
/// than dropped — `gg one can commit` subscribes one microtask after the
/// start and must not miss the first line.
class _StreamingProcess implements Process {
  _StreamingProcess(this._started) {
    _started.onStdout(_stdout.add);
    _started.onStderr(_stderr.add);
    _started.onExit((code) {
      if (!_stdout.isClosed) _stdout.close();
      if (!_stderr.isClosed) _stderr.close();
      if (!_exit.isCompleted) _exit.complete(code);
    });
  }

  final GgStartedProcess _started;
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exit = Completer<int>();

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  late final IOSink stdin = GgHostIoSink(
    encoding: utf8,
    onWrite: _started.writeStdin,
    onClose: _started.closeStdin,
  );

  @override
  int get pid => _started.pid;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      _started.kill(signal.toString());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('Process.${invocation.memberName}');
}

// #############################################################################
/// A [Process] that has already finished and replays its recorded output.
class _CompletedProcess implements Process {
  _CompletedProcess(this._outcome);

  final GgProcessOutcome _outcome;

  @override
  Future<int> get exitCode async => _outcome.exitCode;

  @override
  Stream<List<int>> get stdout =>
      Stream<List<int>>.value(utf8.encode(_outcome.stdout));

  @override
  Stream<List<int>> get stderr =>
      Stream<List<int>>.value(utf8.encode(_outcome.stderr));

  @override
  IOSink get stdin => GgHostIoSink(encoding: utf8, onWrite: (_) {});

  @override
  int get pid => _outcome.pid;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('Process.${invocation.memberName}');
}

// #############################################################################
/// Answers platform questions through [GgPlatformCallbacks].
class _HostPlatformDelegate extends GgPlatformDelegate {
  _HostPlatformDelegate(this._callbacks);

  final GgPlatformCallbacks _callbacks;

  @override
  Map<String, String> get environment => _callbacks.environment();

  @override
  String get operatingSystem => _callbacks.operatingSystem();

  @override
  String get pathSeparator => _callbacks.pathSeparator();

  @override
  int get exitCode => _callbacks.exitCode();

  @override
  set exitCode(int value) => _callbacks.setExitCode(value);
}

// #############################################################################
/// Draws the prompts through [GgPromptCallbacks].
class _HostPrompts extends GgPrompts {
  const _HostPrompts(this._callbacks);

  final GgPromptCallbacks _callbacks;

  @override
  Future<int> select({
    required String prompt,
    required List<String> options,
    int initialIndex = 0,
  }) => _callbacks.select(prompt, options, initialIndex);

  @override
  Future<String> input({
    required String prompt,
    String? defaultValue,
    String? initialText,
    bool asMessageEditor = false,
  }) => _callbacks.input(
    prompt,
    defaultValue ?? '',
    initialText ?? '',
    asMessageEditor,
  );
}
