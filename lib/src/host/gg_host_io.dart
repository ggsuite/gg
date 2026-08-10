// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'gg_host.dart';
import 'gg_host_callbacks.dart';

/// A [GgHost] that answers every callback with `dart:io`.
///
/// It is the reference implementation of the callback contract, and the
/// yardstick an embedder is measured against: installing it must leave gg
/// behaving exactly as it does without any host at all. The gg test suite
/// runs against it for precisely that reason.
///
/// It is not what the native `gg` executable uses — that one talks to
/// `dart:io` directly, without the detour.
abstract final class GgHostIo {
  /// Builds the host.
  static GgHost create() => GgHost(
    fileSystem: fileSystem,
    process: process,
    platform: platform,
    console: console,
  );

  // ...........................................................................
  /// File access through `dart:io`.
  static final GgFileSystemCallbacks fileSystem = GgFileSystemCallbacks(
    typeOf: (path, followLinks) => _raw(() {
      final type = FileSystemEntity.typeSync(path, followLinks: followLinks);
      if (type == FileSystemEntityType.file) return GgEntityType.file;
      if (type == FileSystemEntityType.directory) {
        return GgEntityType.directory;
      }
      if (type == FileSystemEntityType.link) return GgEntityType.link;
      return GgEntityType.notFound;
    }),
    readBytes: (path) => _raw(() => File(path).readAsBytesSync()),
    writeBytes: (path, bytes, append) => _raw(
      () => File(path).writeAsBytesSync(
        bytes,
        mode: append ? FileMode.append : FileMode.write,
      ),
    ),
    createDirectory: (path, recursive) =>
        _raw(() => Directory(path).createSync(recursive: recursive)),
    createFile: (path, recursive) =>
        _raw(() => File(path).createSync(recursive: recursive)),
    deleteEntity: (path, recursive) => _raw(() {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        Directory(path).deleteSync(recursive: recursive);
      } else if (type == FileSystemEntityType.link) {
        Link(path).deleteSync();
      } else {
        File(path).deleteSync();
      }
    }),
    listDirectory: (path, recursive) => _raw(
      () => Directory(path)
          .listSync(recursive: recursive, followLinks: false)
          .map(
            (e) => GgDirectoryEntry(
              path: e.path,
              type: switch (e) {
                Directory() => GgEntityType.directory,
                Link() => GgEntityType.link,
                _ => GgEntityType.file,
              },
            ),
          )
          .toList(),
    ),
    rename: (from, to) => _raw(() {
      final type = FileSystemEntity.typeSync(from, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        Directory(from).renameSync(to);
      } else {
        File(from).renameSync(to);
      }
    }),
    copyFile: (from, to) => _raw(() => File(from).copySync(to)),
    currentDirectory: () => _raw(() => Directory.current.path),
    setCurrentDirectory: (path) => _raw(() => Directory.current = path),
    systemTempDirectory: () => _raw(() => Directory.systemTemp.path),
    createTempDirectory: (parent, prefix) =>
        _raw(() => Directory(parent).createTempSync(prefix).path),
    resolveSymbolicLinks: (path) =>
        _raw(() => File(path).resolveSymbolicLinksSync()),
    createLink: (link, target) => _raw(() => Link(link).createSync(target)),
    linkTarget: (link) => _raw(() => Link(link).targetSync()),
  );

  // ...........................................................................
  /// Process execution through `dart:io`.
  static final GgProcessCallbacks process = GgProcessCallbacks(
    run:
        (
          executable,
          arguments, {
          workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
        }) async {
          final result = await Process.run(
            executable,
            arguments,
            workingDirectory: workingDirectory,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            runInShell: runInShell,
          );
          return GgProcessOutcome(
            exitCode: result.exitCode,
            stdout: '${result.stdout}',
            stderr: '${result.stderr}',
            pid: result.pid,
          );
        },
    start:
        (
          executable,
          arguments, {
          workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          detached = false,
        }) async => _IoStartedProcess(
          await Process.start(
            executable,
            arguments,
            workingDirectory: workingDirectory,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            runInShell: runInShell,
            mode: detached
                ? ProcessStartMode.detached
                : ProcessStartMode.normal,
          ),
        ),
  );

  // ...........................................................................
  /// Platform questions answered by `dart:io`.
  static final GgPlatformCallbacks platform = GgPlatformCallbacks(
    environment: () => Platform.environment,
    operatingSystem: () => Platform.operatingSystem,
    pathSeparator: () => Platform.pathSeparator,
    setExitCode: (code) => exitCode = code,
    exitCode: () => exitCode,
  );

  // ...........................................................................
  /// Console access through `dart:io`.
  static final GgConsoleCallbacks console = GgConsoleCallbacks(
    writeStdout: (text) => _raw(() => stdout.write(text)),
    writeStderr: (text) => _raw(() => stderr.write(text)),
    readLine: () => _raw(() => stdin.readLineSync()),
    hasTerminal: () => _raw(() => stdout.hasTerminal),
    supportsAnsiEscapes: () => _raw(() => stdout.supportsAnsiEscapes),
    terminalColumns: () =>
        _raw(() => stdout.hasTerminal ? stdout.terminalColumns : 80),
  );
}

// .............................................................................
/// Runs [body] with `IOOverrides.global` temporarily cleared.
///
/// Without this the callbacks below would be routed back into themselves:
/// `GgHost.install` points `IOOverrides.global` at the very callbacks that
/// then create the `File` objects here. [body] must be synchronous — the
/// override is restored before the next event loop turn.
///
/// Only the global override is cleared, which is the one [GgHost.install]
/// sets. A zone-scoped `IOOverrides.runZoned` around gg would still win.
T _raw<T>(T Function() body) {
  final saved = IOOverrides.current;
  if (saved == null) return body();

  IOOverrides.global = null;
  try {
    return body();
  } finally {
    IOOverrides.global = saved;
  }
}

// #############################################################################
/// A [GgStartedProcess] wrapping a `dart:io` [Process].
///
/// Subscribes to the process' output immediately and buffers it: a program
/// can be done before the caller registers its listeners, and gg reading
/// an empty run is exactly the failure this layer exists to avoid.
class _IoStartedProcess implements GgStartedProcess {
  _IoStartedProcess(this._process) {
    _process.stdout.listen(
      (data) => _push(_outBuffer, () => _outListener, data),
      onDone: () {
        _outDone = true;
        _finishWhenReady();
      },
    );
    _process.stderr.listen(
      (data) => _push(_errBuffer, () => _errListener, data),
      onDone: () {
        _errDone = true;
        _finishWhenReady();
      },
    );
    unawaited(
      _process.exitCode.then((code) {
        _code = code;
        _finishWhenReady();
      }),
    );
  }

  final Process _process;
  final _outBuffer = <Uint8List>[];
  final _errBuffer = <Uint8List>[];
  void Function(Uint8List)? _outListener;
  void Function(Uint8List)? _errListener;
  void Function(int)? _exitListener;
  bool _outDone = false;
  bool _errDone = false;
  bool _finished = false;
  int? _code;

  @override
  int get pid => _process.pid;

  @override
  void onStdout(void Function(Uint8List chunk) listener) {
    _outListener = listener;
    _drain(_outBuffer, listener);
  }

  @override
  void onStderr(void Function(Uint8List chunk) listener) {
    _errListener = listener;
    _drain(_errBuffer, listener);
  }

  @override
  void onExit(void Function(int code) listener) {
    _exitListener = listener;
    if (_finished) listener(_code!);
    _finishWhenReady();
  }

  @override
  void writeStdin(String text) => _process.stdin.write(text);

  @override
  void closeStdin() => unawaited(_process.stdin.close());

  @override
  bool kill(String signal) => _process.kill(_signalFrom(signal));

  void _push(
    List<Uint8List> buffer,
    void Function(Uint8List)? Function() listener,
    List<int> data,
  ) {
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    final sink = listener();
    if (sink != null) {
      sink(bytes);
    } else {
      buffer.add(bytes);
    }
  }

  void _drain(List<Uint8List> buffer, void Function(Uint8List) listener) {
    while (buffer.isNotEmpty) {
      listener(buffer.removeAt(0));
    }
  }

  /// Reports the exit only once both output streams have run dry.
  ///
  /// `Process.exitCode` completes as soon as the program is gone, which can
  /// be before the last bytes have been delivered.
  void _finishWhenReady() {
    if (_finished || _code == null || !_outDone || !_errDone) return;
    _finished = true;
    _exitListener?.call(_code!);
  }

  static ProcessSignal _signalFrom(String name) =>
      switch (name.toUpperCase().replaceFirst('PROCESSSIGNAL.', '')) {
        'SIGKILL' => ProcessSignal.sigkill,
        'SIGINT' => ProcessSignal.sigint,
        'SIGHUP' => ProcessSignal.sighup,
        _ => ProcessSignal.sigterm,
      };
}
