// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The `dart:io` stand-ins, driven directly.
//
// `gg_host_io_test.dart` exercises the same classes through `GgHostIo`
// against a real disk — that is the fidelity check. This file is about the
// parts a real disk cannot reach: the members gg never calls (which must
// fail with a message naming them, not obscurely), the console, and the
// sinks.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gg/gg.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'dart_io_conformance.dart';

/// The working directory of the fake file system, spelled the way the
/// platform spells an absolute path — `/work` on posix, `\work` on
/// Windows. The subject normalizes what it is given, so a hard coded
/// `/work` would only match on one of them.
final String _workDir = p.join(p.separator, 'work');

// .............................................................................
/// The smallest file system that answers at all.
GgFileSystemCallbacks _emptyFs() => GgFileSystemCallbacks(
  typeOf: (_, _) => GgEntityType.notFound,
  readBytes: (_) => Uint8List(0),
  writeBytes: (_, _, _) {},
  createDirectory: (_, _) {},
  createFile: (_, _) {},
  deleteEntity: (_, _) {},
  listDirectory: (_, _) => const [],
  rename: (_, _) {},
  copyFile: (_, _) {},
  currentDirectory: () => _workDir,
  setCurrentDirectory: (_) {},
  systemTempDirectory: () => '/tmp',
  createTempDirectory: (_, _) => '/tmp/x',
  resolveSymbolicLinks: (path) => path,
  createLink: (_, _) {},
  linkTarget: (_) => '/target',
);

void main() {
  // The shared `dart:io` conformance suite: every entity in it is one
  // of the classes this file is about.
  dartIoConformanceTests();

  // ###########################################################################
  group('GgHostIoOverrides', () {
    late GgHostIoOverrides overrides;
    late List<String> out;
    late List<String> err;
    late List<int> exits;

    setUp(() {
      out = [];
      err = [];
      exits = [];
      overrides = GgHostIoOverrides(
        fileSystem: _emptyFs(),
        console: GgConsoleCallbacks(
          writeStdout: out.add,
          writeStderr: err.add,
          readLine: () => 'answer',
        ),
        onExit: (code) {
          exits.add(code);
          throw StateError('exited');
        },
      );
    });

    test('hands out entities served by the callbacks', () {
      // These are what `File(...)`, `Directory(...)` and `Link(...)` become
      // once the overrides are installed.
      expect(overrides.createFile('/a.txt'), isA<GgHostFile>());
      expect(overrides.createDirectory('/d'), isA<GgHostDirectory>());
      expect(overrides.createLink('/l'), isA<GgHostLink>());
    });

    test('resolves a relative path against the working directory', () {
      // gg hands `dart:io` relative paths all the time; the host only ever
      // sees absolute ones.
      final seen = <String>[];
      final fs = _emptyFs();
      final probing = GgFileSystemCallbacks(
        typeOf: (path, _) {
          seen.add(path);
          return GgEntityType.notFound;
        },
        readBytes: fs.readBytes,
        writeBytes: fs.writeBytes,
        createDirectory: fs.createDirectory,
        createFile: fs.createFile,
        deleteEntity: fs.deleteEntity,
        listDirectory: fs.listDirectory,
        rename: fs.rename,
        copyFile: fs.copyFile,
        currentDirectory: fs.currentDirectory,
        setCurrentDirectory: fs.setCurrentDirectory,
        systemTempDirectory: fs.systemTempDirectory,
        createTempDirectory: fs.createTempDirectory,
        resolveSymbolicLinks: fs.resolveSymbolicLinks,
        createLink: fs.createLink,
        linkTarget: fs.linkTarget,
      );

      GgHostFile(probing, 'relative.txt').existsSync();
      final absolute = p.join(p.separator, 'absolute.txt');
      GgHostFile(probing, absolute).existsSync();

      expect(seen, [p.join(_workDir, 'relative.txt'), absolute]);
    });

    test('spells absolute and parent the way dart:io does', () {
      final fs = _emptyFs();

      // `absolute` resolves, `parent` keeps the caller's spelling — gg
      // compares listed paths against ones it builds itself, and mixing
      // the two makes those comparisons match nothing.
      expect(
        GgHostFile(fs, 'rel.txt').absolute.path,
        p.join(_workDir, 'rel.txt'),
      );
      expect(GgHostFile(fs, 'a/b.txt').parent.path, 'a');
      expect(
        GgHostDirectory(fs, 'a/b').absolute.path,
        p.join(_workDir, 'a', 'b'),
      );
      expect(GgHostDirectory(fs, 'a/b').parent.path, 'a');
      expect(GgHostLink(fs, 'a/l').absolute.path, p.join(_workDir, 'a', 'l'));
      expect(GgHostLink(fs, 'a/l').parent.path, 'a');

      expect(GgHostFile(fs, '/a.txt').uri, Uri.file('/a.txt'));
      expect(GgHostDirectory(fs, '/d').uri, Uri.directory('/d'));
      expect(GgHostLink(fs, '/l').uri, Uri.file('/l'));
    });

    test('answers the current and temporary directories', () {
      expect(overrides.getCurrentDirectory().path, _workDir);
      expect(overrides.getSystemTempDirectory().path, '/tmp');
      expect(
        () => overrides.setCurrentDirectory('/elsewhere'),
        returnsNormally,
      );
    });

    test(
      'answers the type questions synchronously and asynchronously',
      () async {
        expect(overrides.statSync('/a').type, FileSystemEntityType.notFound);
        expect(
          (await overrides.stat('/a')).type,
          FileSystemEntityType.notFound,
        );
        expect(
          overrides.fseGetTypeSync('/a', true),
          FileSystemEntityType.notFound,
        );
        expect(
          await overrides.fseGetType('/a', true),
          FileSystemEntityType.notFound,
        );
      },
    );

    test('compares identity through the resolved paths', () async {
      // The stub file system resolves every path to itself, so equal
      // paths are identical and different ones are not.
      expect(overrides.fseIdenticalSync('/a', '/a'), isTrue);
      expect(await overrides.fseIdentical('/a', '/b'), isFalse);
    });

    test('serves stdout, stderr and stdin from the console callbacks', () {
      overrides.stdout.write('to out');
      overrides.stderr.write('to err');

      expect(out, ['to out']);
      expect(err, ['to err']);
      expect(overrides.stdin.readLineSync(), 'answer');
      // The same objects each time — gg holds on to them.
      expect(overrides.stdout, same(overrides.stdout));
      expect(overrides.stderr, same(overrides.stderr));
      expect(overrides.stdin, same(overrides.stdin));
    });

    test('routes exit through the callback instead of ending the process', () {
      expect(() => overrides.exit(3), throwsStateError);
      expect(exits, [3]);
    });
  });

  // ###########################################################################
  group('unsupported members', () {
    test('name themselves instead of failing obscurely', () {
      final fs = _emptyFs();

      // gg only uses a slice of `dart:io`. Anything outside it must say so
      // — an embedder reading »File.openSync is not supported by the
      // installed gg host« knows what to implement; a NoSuchMethodError
      // does not.
      expect(
        () => GgHostFile(fs, '/a.txt').openSync(),
        throwsA(
          isA<GgHostUnsupportedError>().having(
            (e) => e.message,
            'message',
            allOf(contains('File.openSync'), contains('/a.txt')),
          ),
        ),
      );
      expect(
        () => GgHostDirectory(fs, '/d').watch(),
        throwsA(isA<GgHostUnsupportedError>()),
      );
      expect(
        () => GgHostLink(fs, '/l').watch(),
        throwsA(isA<GgHostUnsupportedError>()),
      );
    });

    test('watching is refused by name', () {
      final overrides = GgHostIoOverrides(
        fileSystem: _emptyFs(),
        console: GgConsoleCallbacks(writeStdout: (_) {}, writeStderr: (_) {}),
        onExit: (code) => throw StateError('exit $code'),
      );

      expect(overrides.fsWatchIsSupported(), isFalse);
      expect(
        () => overrides.fsWatch('/a', 0, false),
        throwsA(
          isA<GgHostUnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('/a'),
          ),
        ),
      );
    });
  });

  // ###########################################################################
  group('GgHostFileStat', () {
    test('reports the type and neutral values for the rest', () {
      // gg only ever asks for the type; the other fields exist so that
      // printing a stat does not blow up.
      final stat = GgHostFileStat(GgEntityType.link);

      expect(stat.type, FileSystemEntityType.link);
      expect(stat.size, 0);
      expect(stat.mode, 0);
      expect(stat.modeString(), '---------');
      expect(stat.accessed, DateTime.fromMillisecondsSinceEpoch(0));
      expect(stat.changed, DateTime.fromMillisecondsSinceEpoch(0));
      expect(stat.modified, DateTime.fromMillisecondsSinceEpoch(0));
      expect(stat.toString(), contains('link'));
    });

    test('refuses anything else by name', () {
      expect(
        () =>
            GgHostFileStat(GgEntityType.file)
                .noSuchMethod(Invocation.getter(#somethingElse)),
        throwsA(isA<GgHostUnsupportedError>()),
      );
    });
  });

  // ###########################################################################
  group('GgHostStdout', () {
    late List<String> written;
    late GgHostStdout out;

    setUp(() {
      written = [];
      out = GgHostStdout(
        GgConsoleCallbacks(
          writeStdout: written.add,
          writeStderr: (_) {},
          hasTerminal: () => true,
          supportsAnsiEscapes: () => true,
          terminalColumns: () => 120,
        ),
        written.add,
      );
    });

    test('writes every way an IOSink can be written to', () async {
      out.write('a');
      out.writeln('b');
      out.writeAll(['c', 'd'], '-');
      out.writeCharCode(33);
      out.add(utf8.encode('!'));
      await out.addStream(Stream<List<int>>.value(utf8.encode('#')));

      expect(written.join(), 'ab\nc-d!!#');
    });

    test('writes the word null rather than nothing', () {
      out.write(null);
      out.writeln(null);
      expect(written.join(), 'nullnull\n');
    });

    test('answers the terminal questions from the console callbacks', () {
      expect(out.hasTerminal, isTrue);
      expect(out.supportsAnsiEscapes, isTrue);
      expect(out.terminalColumns, 120);
      expect(out.terminalLines, greaterThan(0));
      expect(out.nonBlocking, same(out));
      expect(out.encoding, utf8);
    });

    test('closes and flushes without complaint', () async {
      await out.flush();
      await out.close();
      await out.done;
    });

    test('rethrows what is handed to addError', () {
      expect(() => out.addError(StateError('boom')), throwsStateError);
    });

    test('refuses anything else by name', () {
      expect(
        () => out.noSuchMethod(Invocation.getter(#somethingElse)),
        throwsA(
          isA<GgHostUnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('somethingElse'),
          ),
        ),
      );
    });
  });

  // ###########################################################################
  group('GgHostStdin', () {
    test('reads the lines the console hands out', () {
      final lines = ['first', 'second'];
      final stdin = GgHostStdin(
        GgConsoleCallbacks(
          writeStdout: (_) {},
          writeStderr: (_) {},
          readLine: () => lines.isEmpty ? null : lines.removeAt(0),
          hasTerminal: () => true,
        ),
      );

      expect(stdin.readLineSync(), 'first');
      expect(stdin.readLineSync(retainNewlines: true), 'second\n');
      expect(stdin.readLineSync(), isNull);
      expect(stdin.hasTerminal, isTrue);
    });

    test('refuses to read when the host offers no stdin', () {
      // A host without `readLine` says »nobody is there to answer«, which
      // is better than a read that never returns.
      final stdin = GgHostStdin(
        GgConsoleCallbacks(writeStdout: (_) {}, writeStderr: (_) {}),
      );

      expect(
        () => stdin.readLineSync(),
        throwsA(
          isA<GgHostUnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('stdin'),
          ),
        ),
      );
    });

    test('streams the lines it can read', () async {
      final lines = ['one', 'two'];
      final stdin = GgHostStdin(
        GgConsoleCallbacks(
          writeStdout: (_) {},
          writeStderr: (_) {},
          readLine: () => lines.isEmpty ? null : lines.removeAt(0),
        ),
      );

      final read = <List<int>>[];
      await stdin.listen(read.add).asFuture<void>();

      expect(read.map(utf8.decode).join(), 'one\ntwo\n');
    });

    test('streams nothing when the host offers no stdin', () async {
      final stdin = GgHostStdin(
        GgConsoleCallbacks(writeStdout: (_) {}, writeStderr: (_) {}),
      );

      final read = <List<int>>[];
      await stdin.listen(read.add).asFuture<void>();
      expect(read, isEmpty);
    });

    test('refuses anything else by name', () {
      // `Stdin` is a `Stream`, and gg only ever reads it with
      // `readLineSync` or `listen`. Everything else says so rather than
      // failing as a NoSuchMethodError.
      final stdin = GgHostStdin(
        GgConsoleCallbacks(writeStdout: (_) {}, writeStderr: (_) {}),
      );

      expect(
        () => stdin.transform(utf8.decoder),
        throwsA(
          isA<GgHostUnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('stdin.transform'),
          ),
        ),
      );
    });
  });

  // ###########################################################################
  group('GgHostIoSink', () {
    test('forwards everything written to it', () async {
      final written = <String>[];
      final sink = GgHostIoSink(encoding: utf8, onWrite: written.add);

      sink.write('a');
      sink.writeln('b');
      sink.writeAll(['c', 'd'], '-');
      sink.writeCharCode(33);
      sink.add(utf8.encode('!'));
      await sink.addStream(Stream<List<int>>.value(utf8.encode('#')));
      await sink.flush();
      await sink.done;

      expect(written.join(), 'ab\nc-d!!#');
    });

    test('calls onClose so a program waiting on stdin can finish', () async {
      var closed = false;
      final sink = GgHostIoSink(
        encoding: utf8,
        onWrite: (_) {},
        onClose: () => closed = true,
      );

      await sink.close();
      expect(closed, isTrue);
    });

    test('closes fine without an onClose', () async {
      final sink = GgHostIoSink(encoding: utf8, onWrite: (_) {});
      await sink.close();
    });

    test('rethrows what is handed to addError', () {
      final sink = GgHostIoSink(encoding: utf8, onWrite: (_) {});
      expect(() => sink.addError(StateError('boom')), throwsStateError);
    });

    test('refuses anything else by name', () {
      final sink = GgHostIoSink(encoding: utf8, onWrite: (_) {});
      expect(
        () => sink.noSuchMethod(Invocation.getter(#somethingElse)),
        throwsA(isA<GgHostUnsupportedError>()),
      );
    });
  });
}
