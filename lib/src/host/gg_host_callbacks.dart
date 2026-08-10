// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'dart:typed_data';

/// What a path points to.
///
/// Mirrors `FileSystemEntityType` without depending on it, so an embedder can
/// answer with a plain value.
enum GgEntityType {
  /// Nothing exists at the path.
  notFound,

  /// A regular file.
  file,

  /// A directory.
  directory,

  /// A symbolic link.
  link,
}

// .............................................................................
/// One entry of a directory listing.
class GgDirectoryEntry {
  /// Default constructor
  const GgDirectoryEntry({required this.path, required this.type});

  /// The absolute path of the entry.
  final String path;

  /// What the entry is.
  final GgEntityType type;

  @override
  String toString() => '$path (${type.name})';
}

// .............................................................................
/// The result of running a process to completion.
class GgProcessOutcome {
  /// Default constructor
  const GgProcessOutcome({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.pid = 0,
  });

  /// The exit code the process terminated with.
  final int exitCode;

  /// Everything the process wrote to stdout.
  final String stdout;

  /// Everything the process wrote to stderr.
  final String stderr;

  /// The process id, or `0` when the host does not report one.
  final int pid;
}

// .............................................................................
/// Everything gg needs to read and write files.
///
/// All callbacks are synchronous: `dart:io`'s `…Sync` APIs are used
/// throughout the gg suite and cannot wait for a `Future`. Node answers all
/// of them synchronously via `node:fs`, and the asynchronous `dart:io` APIs
/// are served from the same callbacks.
///
/// Paths handed to the callbacks are always absolute — [GgHost] resolves
/// relative paths against [GgFileSystemCallbacks.currentDirectory] first.
class GgFileSystemCallbacks {
  /// Default constructor
  const GgFileSystemCallbacks({
    required this.typeOf,
    required this.readBytes,
    required this.writeBytes,
    required this.createDirectory,
    required this.createFile,
    required this.deleteEntity,
    required this.listDirectory,
    required this.rename,
    required this.copyFile,
    required this.currentDirectory,
    required this.setCurrentDirectory,
    required this.systemTempDirectory,
    required this.createTempDirectory,
    required this.resolveSymbolicLinks,
    required this.createLink,
    required this.linkTarget,
  });

  /// Returns what [path] points to. `followLinks` resolves symbolic links.
  final GgEntityType Function(String path, bool followLinks) typeOf;

  /// Reads the whole file at [path].
  final Uint8List Function(String path) readBytes;

  /// Writes [bytes] to [path], appending instead of truncating when
  /// `append` is true.
  final void Function(String path, Uint8List bytes, bool append) writeBytes;

  /// Creates the directory at [path], including parents when `recursive`.
  final void Function(String path, bool recursive) createDirectory;

  /// Creates an empty file at [path], including parents when `recursive`.
  /// Does nothing when the file already exists.
  final void Function(String path, bool recursive) createFile;

  /// Deletes the entity at [path], including its content when `recursive`.
  final void Function(String path, bool recursive) deleteEntity;

  /// Lists the directory at [path], descending into it when `recursive`.
  final List<GgDirectoryEntry> Function(String path, bool recursive)
  listDirectory;

  /// Moves the entity at `from` to `to`.
  final void Function(String from, String to) rename;

  /// Copies the file at `from` to `to`.
  final void Function(String from, String to) copyFile;

  /// The working directory of the process.
  final String Function() currentDirectory;

  /// Changes the working directory of the process.
  final void Function(String path) setCurrentDirectory;

  /// The directory for temporary files, e.g. `/tmp`.
  final String Function() systemTempDirectory;

  /// Creates a uniquely named directory below [parent] and returns its path.
  final String Function(String parent, String prefix) createTempDirectory;

  /// Resolves all symbolic links in [path] and returns the real path.
  final String Function(String path) resolveSymbolicLinks;

  /// Creates a symbolic link at `link` pointing to `target`.
  final void Function(String link, String target) createLink;

  /// Returns what the symbolic link at `link` points to.
  final String Function(String link) linkTarget;
}

// .............................................................................
/// Everything gg needs to run other programs.
class GgProcessCallbacks {
  /// Default constructor
  const GgProcessCallbacks({required this.run, this.start});

  /// Runs [executable] with [arguments] and completes when it has finished.
  final Future<GgProcessOutcome> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
  })
  run;

  /// Starts [executable] with [arguments] without waiting for it.
  ///
  /// Optional. When omitted, [run] serves `Process.start` as well: the
  /// process is run to completion and its output is replayed on the
  /// returned streams. Commands that write to the started process' stdin
  /// do not work in that mode.
  final Future<GgProcessOutcome> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    bool detached,
  })?
  start;
}

// .............................................................................
/// Everything gg needs to know about the machine and process it runs in.
class GgPlatformCallbacks {
  /// Default constructor
  const GgPlatformCallbacks({
    required this.environment,
    required this.operatingSystem,
    required this.pathSeparator,
    required this.setExitCode,
    required this.exitCode,
  });

  /// The environment variables of the process.
  final Map<String, String> Function() environment;

  /// The operating system: `macos`, `linux`, `windows`, …
  final String Function() operatingSystem;

  /// The character separating path segments, e.g. `/` or `\`.
  final String Function() pathSeparator;

  /// Records the exit code the process should terminate with.
  final void Function(int code) setExitCode;

  /// The exit code recorded so far.
  final int Function() exitCode;
}

// .............................................................................
/// Everything gg needs to talk to the user's terminal.
class GgConsoleCallbacks {
  /// Default constructor
  const GgConsoleCallbacks({
    required this.writeStdout,
    required this.writeStderr,
    this.readLine,
    this.hasTerminal = _noTerminal,
    this.supportsAnsiEscapes = _noTerminal,
    this.terminalColumns = _defaultColumns,
  });

  /// Writes [text] to stdout. No newline is appended.
  final void Function(String text) writeStdout;

  /// Writes [text] to stderr. No newline is appended.
  final void Function(String text) writeStderr;

  /// Reads one line from stdin, or returns `null` at end of input.
  ///
  /// Optional — when omitted, gg behaves as if stdin were closed, which
  /// makes the interactive commands refuse to run instead of hanging.
  final String? Function()? readLine;

  /// Whether stdout and stdin are attached to a terminal.
  final bool Function() hasTerminal;

  /// Whether the terminal understands ANSI escape sequences.
  final bool Function() supportsAnsiEscapes;

  /// The width of the terminal in characters.
  final int Function() terminalColumns;

  static bool _noTerminal() => false;
  static int _defaultColumns() => 80;
}

// .............................................................................
/// The interactive prompts gg asks its questions with.
///
/// `package:interact`, which draws them on a native build, reaches
/// `dart:ffi` and is therefore absent from a Wasm build. An embedder that
/// can ask the user itself supplies these; one that cannot leaves them out,
/// and gg fails the interactive commands with an actionable message instead
/// of hanging.
class GgPromptCallbacks {
  /// Default constructor
  const GgPromptCallbacks({required this.select, required this.input});

  /// Lets the user pick one of [options] and returns the index picked.
  final int Function(String prompt, List<String> options, int initialIndex)
  select;

  /// Lets the user edit a line of text and returns what they left behind.
  final String Function(
    String prompt,
    String defaultValue,
    String initialText,
    bool asMessageEditor,
  )
  input;
}

// .............................................................................
/// Thrown when gg asks the host for something the embedder does not
/// implement.
class GgHostUnsupportedError extends UnsupportedError {
  /// Default constructor
  GgHostUnsupportedError(String what)
    : super(
        '$what is not supported by the installed gg host. '
        'See GgHost.install(...).',
      );
}

// .............................................................................
/// Turns a [GgProcessOutcome] into a `dart:io` [ProcessResult].
ProcessResult ggProcessResultFrom(GgProcessOutcome outcome) => ProcessResult(
  outcome.pid,
  outcome.exitCode,
  outcome.stdout,
  outcome.stderr,
);
