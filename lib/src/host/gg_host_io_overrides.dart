// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'gg_host_callbacks.dart';

/// Serves `dart:io`'s file system and console APIs from
/// [GgFileSystemCallbacks] and [GgConsoleCallbacks].
///
/// Installing this as `IOOverrides.global` redirects `File`, `Directory`,
/// `Link`, `FileSystemEntity`, `Directory.current`, `stdout`, `stderr`,
/// `stdin` and `exit` for the whole isolate — every gg package included,
/// without a single change at their call sites.
base class GgHostIoOverrides extends IOOverrides {
  /// Default constructor
  GgHostIoOverrides({
    required this.fileSystem,
    required this.console,
    required this.onExit,
  });

  /// Reads and writes files on behalf of `dart:io`.
  final GgFileSystemCallbacks fileSystem;

  /// Serves `stdout`, `stderr` and `stdin`.
  final GgConsoleCallbacks console;

  /// Called by `exit(code)`. Must not return.
  final Never Function(int code) onExit;

  // ...........................................................................
  // File system

  @override
  File createFile(String path) => GgHostFile(fileSystem, path);

  @override
  Directory createDirectory(String path) => GgHostDirectory(fileSystem, path);

  @override
  Link createLink(String path) => GgHostLink(fileSystem, path);

  @override
  Directory getCurrentDirectory() =>
      GgHostDirectory(fileSystem, fileSystem.currentDirectory());

  @override
  void setCurrentDirectory(String path) =>
      fileSystem.setCurrentDirectory(_absolute(fileSystem, path));

  @override
  Directory getSystemTempDirectory() =>
      GgHostDirectory(fileSystem, fileSystem.systemTempDirectory());

  @override
  FileStat statSync(String path) =>
      GgHostFileStat(fileSystem.typeOf(_absolute(fileSystem, path), true));

  @override
  Future<FileStat> stat(String path) async => statSync(path);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      _toFseType(fileSystem.typeOf(_absolute(fileSystem, path), followLinks));

  @override
  Future<FileSystemEntityType> fseGetType(
    String path,
    bool followLinks,
  ) async => fseGetTypeSync(path, followLinks);

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      fileSystem.resolveSymbolicLinks(_absolute(fileSystem, path1)) ==
      fileSystem.resolveSymbolicLinks(_absolute(fileSystem, path2));

  @override
  Future<bool> fseIdentical(String path1, String path2) async =>
      fseIdenticalSync(path1, path2);

  @override
  bool fsWatchIsSupported() => false;

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) =>
      throw GgHostUnsupportedError('Watching $path');

  // ...........................................................................
  // Console

  @override
  Stdout get stdout => _stdout ??= GgHostStdout(console, console.writeStdout);

  @override
  Stdout get stderr => _stderr ??= GgHostStdout(console, console.writeStderr);

  @override
  Stdin get stdin => _stdin ??= GgHostStdin(console);

  @override
  Never exit(int code) => onExit(code);

  Stdout? _stdout;
  Stdout? _stderr;
  Stdin? _stdin;
}

// .............................................................................
/// Resolves [path] against the host's working directory.
String _absolute(GgFileSystemCallbacks fs, String path) => p.isAbsolute(path)
    ? p.normalize(path)
    : p.normalize(p.join(fs.currentDirectory(), path));

// .............................................................................
FileSystemEntityType _toFseType(GgEntityType type) => switch (type) {
  GgEntityType.notFound => FileSystemEntityType.notFound,
  GgEntityType.file => FileSystemEntityType.file,
  GgEntityType.directory => FileSystemEntityType.directory,
  GgEntityType.link => FileSystemEntityType.link,
};

// #############################################################################
/// A `dart:io` [File] served by [GgFileSystemCallbacks].
class GgHostFile implements File {
  /// Default constructor
  GgHostFile(this._fs, this.path);

  final GgFileSystemCallbacks _fs;

  @override
  final String path;

  String get _abs => _absolute(_fs, path);

  @override
  File get absolute => GgHostFile(_fs, _abs);

  @override
  Directory get parent => GgHostDirectory(_fs, p.dirname(path));

  @override
  Uri get uri => Uri.file(path);

  @override
  bool existsSync() => _fs.typeOf(_abs, true) == GgEntityType.file;

  @override
  Future<bool> exists() async => existsSync();

  @override
  File createSync({bool recursive = false, bool exclusive = false}) {
    _fs.createFile(_abs, recursive);
    return this;
  }

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async =>
      createSync(recursive: recursive, exclusive: exclusive);

  @override
  void deleteSync({bool recursive = false}) =>
      _fs.deleteEntity(_abs, recursive);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  Uint8List readAsBytesSync() => _fs.readBytes(_abs);

  @override
  Future<Uint8List> readAsBytes() async => readAsBytesSync();

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      encoding.decode(readAsBytesSync());

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      readAsStringSync(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      const LineSplitter().convert(readAsStringSync(encoding: encoding));

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      readAsLinesSync(encoding: encoding);

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => _fs.writeBytes(
    _abs,
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    mode == FileMode.append || mode == FileMode.writeOnlyAppend,
  );

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  @override
  File renameSync(String newPath) {
    _fs.rename(_abs, _absolute(_fs, newPath));
    return GgHostFile(_fs, newPath);
  }

  @override
  Future<File> rename(String newPath) async => renameSync(newPath);

  @override
  File copySync(String newPath) {
    _fs.copyFile(_abs, _absolute(_fs, newPath));
    return GgHostFile(_fs, newPath);
  }

  @override
  Future<File> copy(String newPath) async => copySync(newPath);

  @override
  int lengthSync() => readAsBytesSync().length;

  @override
  Future<int> length() async => lengthSync();

  @override
  FileStat statSync() => GgHostFileStat(_fs.typeOf(_abs, true));

  @override
  Future<FileStat> stat() async => statSync();

  @override
  String resolveSymbolicLinksSync() => _fs.resolveSymbolicLinks(_abs);

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    final append = mode == FileMode.append || mode == FileMode.writeOnlyAppend;
    if (!append) {
      _fs.writeBytes(_abs, Uint8List(0), false);
    }
    return GgHostIoSink(
      encoding: encoding,
      onWrite: (text) => _fs.writeBytes(_abs, _bytesOf(encoding, text), true),
    );
  }

  @override
  String toString() => "File: '$path'";

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('File.${_nameOf(invocation)} (on $path)');
}

// #############################################################################
/// A `dart:io` [Directory] served by [GgFileSystemCallbacks].
class GgHostDirectory implements Directory {
  /// Default constructor
  GgHostDirectory(this._fs, this.path);

  final GgFileSystemCallbacks _fs;

  @override
  final String path;

  String get _abs => _absolute(_fs, path);

  @override
  Directory get absolute => GgHostDirectory(_fs, _abs);

  @override
  Directory get parent => GgHostDirectory(_fs, p.dirname(path));

  @override
  Uri get uri => Uri.directory(path);

  @override
  bool existsSync() => _fs.typeOf(_abs, true) == GgEntityType.directory;

  @override
  Future<bool> exists() async => existsSync();

  @override
  Directory createSync({bool recursive = false}) {
    _fs.createDirectory(_abs, recursive);
    return this;
  }

  @override
  Future<Directory> create({bool recursive = false}) async =>
      createSync(recursive: recursive);

  @override
  Directory createTempSync([String? prefix]) =>
      GgHostDirectory(_fs, _fs.createTempDirectory(_abs, prefix ?? 'temp'));

  @override
  Future<Directory> createTemp([String? prefix]) async =>
      createTempSync(prefix);

  @override
  void deleteSync({bool recursive = false}) =>
      _fs.deleteEntity(_abs, recursive);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    // `dart:io` prefixes every entry with the directory as the caller
    // spelled it: list `../x` and you get `../x/y`, never `/abs/x/y`. The
    // callbacks answer with absolute paths, so they are spelled back the
    // way they came in. gg compares listed paths against ones it built
    // itself — `gg one can commit` matches coverage files against
    // `join(dir.path, …)` — and an absolute path where a relative one is
    // expected silently matches nothing.
    final base = _abs;
    return _fs
        .listDirectory(base, recursive)
        .map((entry) => _toEntity(entry.type, _asSpelled(entry.path, base)))
        .toList();
  }

  /// Rewrites an absolute [entryPath] the way the caller spelled [path].
  String _asSpelled(String entryPath, String base) => p.isAbsolute(path)
      ? entryPath
      : p.join(path, p.relative(entryPath, from: base));

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => Stream<FileSystemEntity>.fromIterable(
    listSync(recursive: recursive, followLinks: followLinks),
  );

  @override
  Directory renameSync(String newPath) {
    _fs.rename(_abs, _absolute(_fs, newPath));
    return GgHostDirectory(_fs, newPath);
  }

  @override
  Future<Directory> rename(String newPath) async => renameSync(newPath);

  @override
  FileStat statSync() => GgHostFileStat(_fs.typeOf(_abs, true));

  @override
  Future<FileStat> stat() async => statSync();

  @override
  String resolveSymbolicLinksSync() => _fs.resolveSymbolicLinks(_abs);

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  FileSystemEntity _toEntity(GgEntityType type, String entryPath) =>
      switch (type) {
        GgEntityType.directory => GgHostDirectory(_fs, entryPath),
        GgEntityType.link => GgHostLink(_fs, entryPath),
        _ => GgHostFile(_fs, entryPath),
      };

  @override
  String toString() => "Directory: '$path'";

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GgHostUnsupportedError(
    'Directory.${_nameOf(invocation)} (on $path)',
  );
}

// #############################################################################
/// A `dart:io` [Link] served by [GgFileSystemCallbacks].
class GgHostLink implements Link {
  /// Default constructor
  GgHostLink(this._fs, this.path);

  final GgFileSystemCallbacks _fs;

  @override
  final String path;

  String get _abs => _absolute(_fs, path);

  @override
  Link get absolute => GgHostLink(_fs, _abs);

  @override
  Directory get parent => GgHostDirectory(_fs, p.dirname(path));

  @override
  Uri get uri => Uri.file(path);

  @override
  bool existsSync() => _fs.typeOf(_abs, false) == GgEntityType.link;

  @override
  Future<bool> exists() async => existsSync();

  @override
  Link createSync(String target, {bool recursive = false}) {
    if (recursive) {
      _fs.createDirectory(p.dirname(_abs), true);
    }
    _fs.createLink(_abs, target);
    return this;
  }

  @override
  Future<Link> create(String target, {bool recursive = false}) async =>
      createSync(target, recursive: recursive);

  @override
  String targetSync() => _fs.linkTarget(_abs);

  @override
  Future<String> target() async => targetSync();

  @override
  void deleteSync({bool recursive = false}) =>
      _fs.deleteEntity(_abs, recursive);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  String resolveSymbolicLinksSync() => _fs.resolveSymbolicLinks(_abs);

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String toString() => "Link: '$path'";

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('Link.${_nameOf(invocation)} (on $path)');
}

// #############################################################################
/// A minimal [FileStat] carrying just the entity type.
///
/// gg only ever asks for [type]; the remaining fields answer with neutral
/// values so printing a stat does not blow up.
class GgHostFileStat implements FileStat {
  /// Default constructor
  GgHostFileStat(GgEntityType type) : type = _toFseType(type);

  @override
  final FileSystemEntityType type;

  @override
  int get size => 0;

  @override
  int get mode => 0;

  @override
  DateTime get accessed => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  DateTime get changed => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  DateTime get modified => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  String modeString() => '---------';

  @override
  String toString() => 'FileStat: $type';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('FileStat.${_nameOf(invocation)}');
}

// #############################################################################
/// A [Stdout] writing through a [GgConsoleCallbacks] callback.
class GgHostStdout implements Stdout {
  /// Default constructor
  GgHostStdout(this._console, this._write);

  final GgConsoleCallbacks _console;
  final void Function(String text) _write;

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) => _write('${object ?? 'null'}');

  @override
  void writeln([Object? object = '']) => _write('${object ?? 'null'}\n');

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _write(objects.join(separator));

  @override
  void writeCharCode(int charCode) => _write(String.fromCharCode(charCode));

  @override
  void add(List<int> data) => _write(encoding.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) => throw error;

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> get done async {}

  @override
  bool get hasTerminal => _console.hasTerminal();

  @override
  bool get supportsAnsiEscapes => _console.supportsAnsiEscapes();

  @override
  int get terminalColumns => _console.terminalColumns();

  @override
  int get terminalLines => 24;

  @override
  IOSink get nonBlocking => this;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('stdout.${_nameOf(invocation)}');
}

// #############################################################################
/// A [Stdin] reading through a [GgConsoleCallbacks] callback.
class GgHostStdin implements Stdin {
  /// Default constructor
  GgHostStdin(this._console);

  final GgConsoleCallbacks _console;

  @override
  bool get hasTerminal => _console.hasTerminal();

  @override
  bool echoMode = false;

  @override
  bool echoNewlineMode = false;

  @override
  bool lineMode = true;

  @override
  String? readLineSync({
    Encoding encoding = systemEncoding,
    bool retainNewlines = false,
  }) {
    final read = _console.readLine;
    if (read == null) {
      throw GgHostUnsupportedError('Reading from stdin');
    }
    final line = read();
    if (line == null) return null;
    return retainNewlines ? '$line\n' : line;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final read = _console.readLine;
    final lines = <List<int>>[];
    if (read != null) {
      for (String? line = read(); line != null; line = read()) {
        lines.add(utf8.encode('$line\n'));
      }
    }
    return Stream<List<int>>.fromIterable(lines).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('stdin.${_nameOf(invocation)}');
}

// #############################################################################
/// An [IOSink] forwarding everything written to it to a callback.
class GgHostIoSink implements IOSink {
  /// Default constructor
  ///
  /// [onClose] is called by [close] — a started process' stdin has to be
  /// closable, or a program waiting for end of input never finishes.
  GgHostIoSink({
    required this.encoding,
    required void Function(String) onWrite,
    void Function()? onClose,
  }) : _onWrite = onWrite,
       _onClose = onClose;

  final void Function(String text) _onWrite;
  final void Function()? _onClose;

  @override
  Encoding encoding;

  @override
  void write(Object? object) => _onWrite('${object ?? 'null'}');

  @override
  void writeln([Object? object = '']) => _onWrite('${object ?? 'null'}\n');

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _onWrite(objects.join(separator));

  @override
  void writeCharCode(int charCode) => _onWrite(String.fromCharCode(charCode));

  @override
  void add(List<int> data) => _onWrite(encoding.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) => throw error;

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async => _onClose?.call();

  @override
  Future<void> get done async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GgHostUnsupportedError('IOSink.${_nameOf(invocation)}');
}

// .............................................................................
String _nameOf(Invocation invocation) {
  final s = invocation.memberName.toString();
  final match = RegExp(r'Symbol\("(.*)"\)').firstMatch(s);
  return match?.group(1) ?? s;
}

// .............................................................................
Uint8List _bytesOf(Encoding encoding, String text) {
  final bytes = encoding.encode(text);
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
