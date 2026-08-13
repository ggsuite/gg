// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The `dart:io` surface gg uses, exercised against a real disk with
// `GgHostIo` installed.
//
// One suite, two callers. Every `File` here is a [GgHostFile] from
// `gg_host_io_overrides.dart` talking to a callback from `gg_host_io.dart`,
// so the same run proves both halves — and the test files of both call it,
// because gg attributes coverage per test file.
//
// If anything here misbehaves, an embedder would misbehave the same way.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gg/gg.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs the conformance suite. Call from a `main()`.
void dartIoConformanceTests() {
  late Directory tmp;
  late String tmpPath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gg_conformance');
    tmpPath = tmp.resolveSymbolicLinksSync();
    GgHost.install(GgHostIo.create());
  });

  tearDown(() {
    GgHost.uninstall();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('through GgHostIo', () {
    group('files', () {
      test('writes, reads, appends and deletes', () {
        final file = File('$tmpPath/a.txt');
        expect(file.existsSync(), isFalse);

        file.writeAsStringSync('Hello');
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), 'Hello');
        expect(file.readAsBytesSync(), utf8.encode('Hello'));
        expect(file.lengthSync(), 5);

        file.writeAsStringSync(' World', mode: FileMode.append);
        expect(file.readAsStringSync(), 'Hello World');

        file.deleteSync();
        expect(file.existsSync(), isFalse);
      });

      test('serves the async API from the same callbacks', () async {
        final file = File('$tmpPath/async.txt');
        await file.writeAsString('one\ntwo');

        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), 'one\ntwo');
        expect(await file.readAsLines(), ['one', 'two']);
        expect(await file.readAsBytes(), utf8.encode('one\ntwo'));
        expect(await file.length(), 7);
        expect((await file.stat()).type, FileSystemEntityType.file);

        await file.writeAsBytes(utf8.encode('bytes'));
        expect(file.readAsStringSync(), 'bytes');

        await file.delete();
        expect(await file.exists(), isFalse);
      });

      test('creates asynchronously too', () async {
        final file = await File('$tmpPath/async-create.txt').create();
        expect(file.existsSync(), isTrue);

        final nested = await File(
          '$tmpPath/async-nested/deep.txt',
        ).create(recursive: true);
        expect(nested.existsSync(), isTrue);
      });

      test('creates, renames and copies', () {
        File('$tmpPath/new.txt').createSync();
        expect(File('$tmpPath/new.txt').existsSync(), isTrue);

        File('$tmpPath/nested/deep.txt').createSync(recursive: true);
        expect(File('$tmpPath/nested/deep.txt').existsSync(), isTrue);

        File('$tmpPath/new.txt').writeAsStringSync('payload');
        final renamed = File(
          '$tmpPath/new.txt',
        ).renameSync('$tmpPath/moved.txt');
        expect(renamed.readAsStringSync(), 'payload');
        expect(File('$tmpPath/new.txt').existsSync(), isFalse);

        final copy = File('$tmpPath/moved.txt').copySync('$tmpPath/copy.txt');
        expect(copy.readAsStringSync(), 'payload');
      });

      test('renames and copies asynchronously', () async {
        await File('$tmpPath/src.txt').writeAsString('x');
        final renamed = await File(
          '$tmpPath/src.txt',
        ).rename('$tmpPath/dst.txt');
        expect(renamed.readAsStringSync(), 'x');

        final copied = await renamed.copy('$tmpPath/dst2.txt');
        expect(copied.readAsStringSync(), 'x');
      });

      test('reads lines synchronously', () {
        File('$tmpPath/lines.txt').writeAsStringSync('a\nb\nc');
        expect(File('$tmpPath/lines.txt').readAsLinesSync(), ['a', 'b', 'c']);
      });

      test('appends through openWrite', () async {
        final file = File('$tmpPath/sink.txt')..writeAsStringSync('start:');
        final sink = file.openWrite(mode: FileMode.append);
        sink.write('a');
        sink.writeln('b');
        sink.writeAll(['c', 'd'], '-');
        sink.writeCharCode(33);
        sink.add(utf8.encode('!'));
        await sink.flush();
        await sink.close();
        await sink.done;

        expect(file.readAsStringSync(), 'start:ab\nc-d!!');
      });

      test('truncates through openWrite in write mode', () async {
        final file = File('$tmpPath/trunc.txt')..writeAsStringSync('old');
        final sink = file.openWrite();
        sink.write('new');
        await sink.close();

        expect(file.readAsStringSync(), 'new');
      });

      test('exposes path, uri, absolute and parent', () {
        final file = File('$tmpPath/p.txt');
        expect(file.path, '$tmpPath/p.txt');
        expect(file.uri, Uri.file('$tmpPath/p.txt'));
        expect(file.absolute.path, '$tmpPath/p.txt');
        expect(file.parent.path, tmpPath);
        expect(file.toString(), contains('p.txt'));
      });

      test('throws a helpful error for unsupported members', () {
        expect(
          () => File('$tmpPath/x.txt').openSync(),
          throwsA(
            isA<GgHostUnsupportedError>().having(
              (e) => e.message,
              'message',
              allOf(contains('File.openSync'), contains('GgHost.install')),
            ),
          ),
        );
      });
    });

    // #########################################################################

    group('directories', () {
      test('creates, lists, renames and deletes', () {
        final dir = Directory('$tmpPath/d');
        expect(dir.existsSync(), isFalse);

        dir.createSync();
        expect(dir.existsSync(), isTrue);

        Directory('$tmpPath/d/sub/deep').createSync(recursive: true);
        File('$tmpPath/d/file.txt').writeAsStringSync('x');

        final flat = dir.listSync().map((e) => e.path).toList();
        expect(flat, containsAll(['$tmpPath/d/sub', '$tmpPath/d/file.txt']));

        final deep = dir.listSync(recursive: true).map((e) => e.path).toList();
        expect(deep, contains('$tmpPath/d/sub/deep'));

        expect(dir.listSync().whereType<Directory>(), isNotEmpty);
        expect(dir.listSync().whereType<File>(), isNotEmpty);

        dir.renameSync('$tmpPath/renamed');
        expect(Directory('$tmpPath/renamed').existsSync(), isTrue);

        Directory('$tmpPath/renamed').deleteSync(recursive: true);
        expect(Directory('$tmpPath/renamed').existsSync(), isFalse);
      });

      test('serves the async API', () async {
        final dir = await Directory('$tmpPath/async').create();
        expect(await dir.exists(), isTrue);

        await File('$tmpPath/async/f.txt').writeAsString('x');
        expect(await dir.list().length, 1);
        expect((await dir.stat()).type, FileSystemEntityType.directory);

        final renamed = await dir.rename('$tmpPath/async2');
        expect(await renamed.exists(), isTrue);

        await renamed.delete(recursive: true);
        expect(await renamed.exists(), isFalse);
      });

      test('creates temp directories', () async {
        final temp = Directory(tmpPath).createTempSync('pre');
        expect(temp.existsSync(), isTrue);
        expect(temp.path, startsWith('$tmpPath/pre'));

        final temp2 = await Directory(tmpPath).createTemp('other');
        expect(temp2.existsSync(), isTrue);
      });

      test('exposes current and systemTemp', () {
        expect(Directory.current.path, isNotEmpty);
        expect(Directory.systemTemp.path, isNotEmpty);

        final before = Directory.current.path;
        Directory.current = tmpPath;
        expect(Directory.current.resolveSymbolicLinksSync(), tmpPath);
        Directory.current = before;
      });

      test('resolves its symbolic links asynchronously too', () async {
        Directory('$tmpPath/real-dir').createSync();
        expect(
          await Directory('$tmpPath/real-dir').resolveSymbolicLinks(),
          '$tmpPath/real-dir',
        );
      });

      test('exposes path, uri, absolute and parent', () {
        final dir = Directory('$tmpPath/d2');
        expect(dir.uri, Uri.directory('$tmpPath/d2'));
        expect(dir.absolute.path, '$tmpPath/d2');
        expect(dir.parent.path, tmpPath);
        expect(dir.toString(), contains('d2'));
      });

      test('spells listed entries the way the directory was spelled', () {
        // `dart:io` prefixes every entry with the path the caller passed
        // in, and gg compares those against paths it built itself: the
        // coverage check of `gg one can commit` matches listed files
        // against `join(dir.path, …)`. Answering with absolute paths where
        // relative ones are expected makes that comparison match nothing —
        // and a passing test run look like an untested file.
        Directory('$tmpPath/rel/sub').createSync(recursive: true);
        File('$tmpPath/rel/sub/deep.txt').writeAsStringSync('x');
        File('$tmpPath/rel/top.txt').writeAsStringSync('x');

        final before = Directory.current;
        Directory.current = tmpPath;
        addTearDown(() => Directory.current = before);

        final listed = Directory(
          'rel',
        ).listSync(recursive: true).map((e) => e.path).toList()..sort();

        expect(listed, [
          p.join('rel', 'sub'),
          p.join('rel', 'sub', 'deep.txt'),
          p.join('rel', 'top.txt'),
        ]);

        // …and an absolute directory still lists absolute entries.
        final absolute = Directory(
          '$tmpPath/rel',
        ).listSync().map((e) => e.path);
        expect(absolute, everyElement(startsWith('$tmpPath/rel/')));
      });

      test('keeps the spelling in parent as well', () {
        final before = Directory.current;
        Directory.current = tmpPath;
        addTearDown(() => Directory.current = before);

        expect(File(p.join('a', 'b', 'c.txt')).parent.path, p.join('a', 'b'));
        expect(Directory(p.join('a', 'b')).parent.path, 'a');
        expect(File('c.txt').parent.path, '.');
      });

      test('throws a helpful error for unsupported members', () {
        expect(
          () => Directory(tmpPath).watch(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    // #########################################################################

    group('links', () {
      test('creates, reads and deletes a symbolic link', () async {
        File('$tmpPath/target.txt').writeAsStringSync('linked');

        final link = Link('$tmpPath/link.txt')
          ..createSync('$tmpPath/target.txt');
        expect(link.existsSync(), isTrue);
        expect(link.targetSync(), '$tmpPath/target.txt');
        expect(await link.target(), '$tmpPath/target.txt');
        expect(await link.exists(), isTrue);
        expect(link.absolute.path, '$tmpPath/link.txt');
        expect(link.parent.path, tmpPath);
        expect(link.uri, Uri.file('$tmpPath/link.txt'));
        expect(link.toString(), contains('link.txt'));
        expect(link.resolveSymbolicLinksSync(), '$tmpPath/target.txt');
        expect(await link.resolveSymbolicLinks(), '$tmpPath/target.txt');

        link.deleteSync();
        expect(link.existsSync(), isFalse);
      });

      test('creates a link recursively and asynchronously', () async {
        File('$tmpPath/t2.txt').writeAsStringSync('x');
        final link = await Link(
          '$tmpPath/deep/l.txt',
        ).create('$tmpPath/t2.txt', recursive: true);
        expect(link.existsSync(), isTrue);
        await link.delete();
      });

      test('throws a helpful error for unsupported members', () {
        expect(
          () => Link('$tmpPath/l').watch(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    // #########################################################################

    group('FileSystemEntity', () {
      test('answers the type questions', () async {
        File('$tmpPath/f.txt').writeAsStringSync('x');

        expect(FileSystemEntity.isFileSync('$tmpPath/f.txt'), isTrue);
        expect(await FileSystemEntity.isFile('$tmpPath/f.txt'), isTrue);
        expect(FileSystemEntity.isDirectorySync(tmpPath), isTrue);
        expect(
          FileSystemEntity.typeSync('$tmpPath/nope'),
          FileSystemEntityType.notFound,
        );
        expect(
          await FileSystemEntity.type('$tmpPath/f.txt'),
          FileSystemEntityType.file,
        );
      });

      test('compares identity through resolved links', () async {
        File('$tmpPath/i.txt').writeAsStringSync('x');
        Link('$tmpPath/i-link.txt').createSync('$tmpPath/i.txt');

        expect(
          FileSystemEntity.identicalSync('$tmpPath/i.txt', '$tmpPath/i.txt'),
          isTrue,
        );
        File('$tmpPath/i2.txt').writeAsStringSync('y');
        expect(
          await FileSystemEntity.identical('$tmpPath/i.txt', '$tmpPath/i2.txt'),
          isFalse,
        );
        expect(
          FileSystemEntity.identicalSync(
            '$tmpPath/i-link.txt',
            '$tmpPath/i.txt',
          ),
          isTrue,
        );
      });

      test('resolves symbolic links', () async {
        File('$tmpPath/r.txt').writeAsStringSync('x');
        expect(
          File('$tmpPath/r.txt').resolveSymbolicLinksSync(),
          '$tmpPath/r.txt',
        );
        expect(
          await File('$tmpPath/r.txt').resolveSymbolicLinks(),
          '$tmpPath/r.txt',
        );
      });

      test('does not support watching', () {
        expect(FileSystemEntity.isWatchSupported, isFalse);
      });
    });

    // #########################################################################

    group('stat', () {
      test('reports the entity type and neutral values', () {
        File('$tmpPath/s.txt').writeAsStringSync('x');
        final stat = FileStat.statSync('$tmpPath/s.txt');

        expect(stat.type, FileSystemEntityType.file);
        expect(stat.size, 0);
        expect(stat.mode, 0);
        expect(stat.modeString(), '---------');
        expect(stat.accessed, DateTime.fromMillisecondsSinceEpoch(0));
        expect(stat.changed, DateTime.fromMillisecondsSinceEpoch(0));
        expect(stat.modified, DateTime.fromMillisecondsSinceEpoch(0));
        expect(stat.toString(), contains('file'));
      });

      test('serves the async variant', () async {
        File('$tmpPath/s2.txt').writeAsStringSync('x');
        expect(
          (await FileStat.stat('$tmpPath/s2.txt')).type,
          FileSystemEntityType.file,
        );
      });
    });

    // #########################################################################

    group('console', () {
      test('writes through to the real stdout and stderr', () {
        // Nothing to assert beyond »does not throw«: the bytes land on the
        // test runner's own stdout.
        expect(() => stdout.write(''), returnsNormally);
        expect(() => stderr.write(''), returnsNormally);
        expect(stdout.hasTerminal, isA<bool>());
        expect(stdout.supportsAnsiEscapes, isA<bool>());
        expect(stdout.terminalColumns, greaterThan(0));
        expect(stdout.terminalLines, greaterThan(0));
        expect(stdout.encoding, isNotNull);
        expect(stdout.nonBlocking, isNotNull);
      });

      test('accepts every IOSink way of writing', () async {
        expect(() => stdout.writeAll(<String>[], '-'), returnsNormally);
        expect(() => stdout.writeCharCode(32), returnsNormally);
        expect(() => stdout.add(const <int>[]), returnsNormally);
        await stdout.addStream(const Stream<List<int>>.empty());
        await stdout.flush();
        await stdout.close();
        await stdout.done;
      });

      test('rethrows what is handed to addError', () {
        expect(() => stdout.addError(StateError('boom')), throwsStateError);
      });
    });

    // #########################################################################

    group('bytes', () {
      test('round-trips binary content', () {
        final bytes = Uint8List.fromList([0, 1, 2, 253, 254, 255]);
        File('$tmpPath/bin').writeAsBytesSync(bytes);
        expect(File('$tmpPath/bin').readAsBytesSync(), bytes);
      });
    });
  });
}
