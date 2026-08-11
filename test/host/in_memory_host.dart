// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:gg/gg.dart';
import 'package:path/path.dart' as p;

/// A [GgHost] backed by maps instead of a disk.
///
/// It is what an embedder looks like from gg's side: no `dart:io` anywhere,
/// just the callbacks. If gg runs on this, it runs on Node too.
class InMemoryHost {
  /// Default constructor
  InMemoryHost({
    Map<String, String>? environment,
    this.operatingSystem = 'linux',
    this.supportsAnsiEscapes = false,
    this.hasTerminal = false,
    String? workingDirectory,
  }) : environment = environment ?? const {},
       // Rooted the way the platform spells it, so the tests read the
       // same on posix and on Windows.
       workingDirectory = workingDirectory ?? p.join(p.separator, 'work') {
    _directories.add(p.separator);
    _makeDirectories(this.workingDirectory);
  }

  /// The environment the host reports.
  final Map<String, String> environment;

  /// The operating system the host reports.
  final String operatingSystem;

  /// Whether the host claims ANSI support.
  final bool supportsAnsiEscapes;

  /// Whether the host claims a terminal.
  final bool hasTerminal;

  /// The working directory the host starts in.
  String workingDirectory;

  /// Everything written to stdout.
  final StringBuffer stdoutBuffer = StringBuffer();

  /// Everything written to stderr.
  final StringBuffer stderrBuffer = StringBuffer();

  /// The commands the host was asked to run, as `executable arg arg`.
  final List<String> processCalls = [];

  /// Lines [GgConsoleCallbacks.readLine] hands out, oldest first.
  final List<String> stdinLines = [];

  /// The exit code gg asked for.
  int exitCode = 0;

  final Map<String, Uint8List> _files = {};
  final Set<String> _directories = {};
  final Map<String, String> _links = {};
  final Map<String, GgProcessOutcome> _processStubs = {};
  int _tempCounter = 0;

  // ...........................................................................
  /// Puts [content] into the file at [path], creating parent directories.
  void writeFile(String path, String content) {
    _makeDirectories(p.dirname(path));
    _files[path] = Uint8List.fromList(utf8.encode(content));
  }

  /// Reads the file at [path] back.
  String readFile(String path) => utf8.decode(_files[path]!);

  /// Answers `<executable> <args>` with the given outcome.
  void stubProcess(
    String command, {
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  }) => _processStubs[command] = GgProcessOutcome(
    exitCode: exitCode,
    stdout: stdout,
    stderr: stderr,
  );

  // ...........................................................................
  /// The host handed to `GgHost.install`.
  late final GgHost ggHost = GgHost(
    fileSystem: fileSystem,
    process: process,
    platform: platform,
    console: console,
  );

  // ...........................................................................
  /// The file system callbacks.
  late final GgFileSystemCallbacks fileSystem = GgFileSystemCallbacks(
    typeOf: (path, followLinks) {
      final resolved = followLinks ? _resolve(path) : path;
      if (!followLinks && _links.containsKey(path)) return GgEntityType.link;
      if (_files.containsKey(resolved)) return GgEntityType.file;
      if (_directories.contains(resolved)) return GgEntityType.directory;
      return GgEntityType.notFound;
    },
    readBytes: (path) {
      final bytes = _files[_resolve(path)];
      if (bytes == null) {
        throw StateError('No such file: $path');
      }
      return bytes;
    },
    writeBytes: (path, bytes, append) {
      _makeDirectories(p.dirname(path));
      if (append && _files.containsKey(path)) {
        _files[path] = Uint8List.fromList([..._files[path]!, ...bytes]);
      } else {
        _files[path] = bytes;
      }
    },
    createDirectory: (path, recursive) => _makeDirectories(path),
    createFile: (path, recursive) {
      _makeDirectories(p.dirname(path));
      _files.putIfAbsent(path, () => Uint8List(0));
    },
    deleteEntity: (path, recursive) {
      _files.remove(path);
      _links.remove(path);
      _directories.remove(path);
      if (recursive) {
        _files.removeWhere((k, _) => p.isWithin(path, k));
        _directories.removeWhere((k) => p.isWithin(path, k));
      }
    },
    listDirectory: (path, recursive) {
      final entries = <GgDirectoryEntry>[];
      bool matches(String candidate) => recursive
          ? p.isWithin(path, candidate)
          : p.dirname(candidate) == path;

      for (final dir in _directories) {
        if (dir != path && matches(dir)) {
          entries.add(
            GgDirectoryEntry(path: dir, type: GgEntityType.directory),
          );
        }
      }
      for (final file in _files.keys) {
        if (matches(file)) {
          entries.add(GgDirectoryEntry(path: file, type: GgEntityType.file));
        }
      }
      entries.sort((a, b) => a.path.compareTo(b.path));
      return entries;
    },
    rename: (from, to) {
      _makeDirectories(p.dirname(to));
      final file = _files.remove(from);
      if (file != null) {
        _files[to] = file;
        return;
      }
      if (_directories.remove(from)) {
        _directories.add(to);
        for (final key in _files.keys.toList()) {
          if (p.isWithin(from, key)) {
            _files[p.join(to, p.relative(key, from: from))] = _files.remove(
              key,
            )!;
          }
        }
      }
    },
    copyFile: (from, to) {
      _makeDirectories(p.dirname(to));
      _files[to] = _files[from]!;
    },
    currentDirectory: () => workingDirectory,
    setCurrentDirectory: (path) => workingDirectory = path,
    systemTempDirectory: () => '/tmp',
    createTempDirectory: (parent, prefix) {
      final path = p.join(parent, '$prefix${_tempCounter++}');
      _makeDirectories(path);
      return path;
    },
    resolveSymbolicLinks: _resolve,
    createLink: (link, target) {
      _makeDirectories(p.dirname(link));
      _links[link] = target;
    },
    linkTarget: (link) => _links[link]!,
  );

  // ...........................................................................
  /// The process callbacks.
  late final GgProcessCallbacks process = GgProcessCallbacks(
    run:
        (
          executable,
          arguments, {
          workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
        }) async {
          final command = '$executable ${arguments.join(' ')}'.trim();
          processCalls.add(command);
          return _processStubs[command] ??
              const GgProcessOutcome(exitCode: 0, stdout: '', stderr: '');
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
        }) async {
          final command = '$executable ${arguments.join(' ')}'.trim();
          processCalls.add(command);
          final outcome =
              _processStubs[command] ??
              const GgProcessOutcome(exitCode: 0, stdout: '', stderr: '');
          return startedProcess = FakeStartedProcess(outcome);
        },
  );

  /// The process most recently handed out by the `start` callback.
  FakeStartedProcess? startedProcess;

  // ...........................................................................
  /// The platform callbacks.
  late final GgPlatformCallbacks platform = GgPlatformCallbacks(
    environment: () => environment,
    operatingSystem: () => operatingSystem,
    pathSeparator: () => operatingSystem == 'windows' ? r'\' : '/',
    setExitCode: (code) => exitCode = code,
    exitCode: () => exitCode,
  );

  // ...........................................................................
  /// The console callbacks.
  late final GgConsoleCallbacks console = GgConsoleCallbacks(
    writeStdout: stdoutBuffer.write,
    writeStderr: stderrBuffer.write,
    readLine: () => stdinLines.isEmpty ? null : stdinLines.removeAt(0),
    hasTerminal: () => hasTerminal,
    supportsAnsiEscapes: () => supportsAnsiEscapes,
    terminalColumns: () => 80,
  );

  // ...........................................................................
  void _makeDirectories(String path) {
    var current = path;
    while (current.isNotEmpty && !_directories.contains(current)) {
      _directories.add(current);
      final parent = p.dirname(current);
      if (parent == current) break;
      current = parent;
    }
  }

  String _resolve(String path) {
    for (final entry in _links.entries) {
      if (path == entry.key) return entry.value;
      if (p.isWithin(entry.key, path)) {
        return p.join(entry.value, p.relative(path, from: entry.key));
      }
    }
    return path;
  }
}

// #############################################################################
/// A [GgStartedProcess] that emits a recorded outcome one line at a time.
///
/// Line by line on purpose: gg parses `dart test`'s output per chunk, and a
/// host that hands over the whole run at once is exactly the bug this
/// exists to catch.
class FakeStartedProcess implements GgStartedProcess {
  /// Default constructor
  FakeStartedProcess(this._outcome);

  final GgProcessOutcome _outcome;

  /// Everything that was written to the process' stdin.
  final StringBuffer stdinBuffer = StringBuffer();

  /// Whether stdin was closed.
  bool stdinClosed = false;

  /// The signal the process was killed with, if any.
  String? killedWith;

  @override
  int get pid => _outcome.pid;

  @override
  void onStdout(void Function(Uint8List chunk) listener) => _stdout = listener;

  @override
  void onStderr(void Function(Uint8List chunk) listener) => _stderr = listener;

  @override
  void onExit(void Function(int code) listener) {
    _exit = listener;
    // Deliver once every listener is attached, the way a real host does.
    scheduleMicrotask(_deliver);
  }

  @override
  void writeStdin(String text) => stdinBuffer.write(text);

  @override
  void closeStdin() => stdinClosed = true;

  @override
  bool kill(String signal) {
    killedWith = signal;
    return true;
  }

  void _deliver() {
    for (final line in const LineSplitter().convert(_outcome.stdout)) {
      _stdout?.call(Uint8List.fromList(utf8.encode('$line\n')));
    }
    for (final line in const LineSplitter().convert(_outcome.stderr)) {
      _stderr?.call(Uint8List.fromList(utf8.encode('$line\n')));
    }
    _exit?.call(_outcome.exitCode);
  }

  void Function(Uint8List)? _stdout;
  void Function(Uint8List)? _stderr;
  void Function(int)? _exit;
}
