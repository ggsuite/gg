// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

import 'dart_io_conformance.dart';

/// `GgHostIo` itself: the callbacks that answer with `dart:io`.
///
/// The `dart:io` stand-ins they feed — `File`, `Directory`, `Link` — are
/// `gg_host_io_overrides_test.dart`'s subject, driven the same way.
void main() {
  // The same conformance suite: it drives these callbacks through
  // `dart:io`'s own API, which is how gg reaches them.
  dartIoConformanceTests();

  late Directory tmp;
  late String tmpPath;
  late String helper;

  /// The Dart executable running these tests.
  ///
  /// The process tests need a program to start, and `echo`, `cat`, `sh`
  /// and `sleep` are not it: none of them is an executable on Windows.
  /// The Dart binary is, on every platform the suite runs on.
  final dart = Platform.resolvedExecutable;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gg_host_io');
    tmpPath = tmp.resolveSymbolicLinksSync();

    // Written before the host is installed, so it is a plain file on disk
    // no matter what the tests do to `dart:io` afterwards.
    helper = '$tmpPath/helper.dart';
    File(helper).writeAsStringSync(_helperSource);

    GgHost.install(GgHostIo.create());
  });

  tearDown(() {
    GgHost.uninstall();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('GgHostIo', () {
    // #########################################################################
    group('processes', () {
      test('runs a real process through the callbacks', () async {
        const wrapper = GgProcessWrapper();
        final result = await wrapper.run(dart, [helper, 'emit', 'from-host']);

        expect(result.exitCode, 0);
        expect(result.stdout, contains('from-host'));
      });

      test('streams a started process while it runs', () async {
        const wrapper = GgProcessWrapper();
        final process = await wrapper.start(dart, [helper, 'emit', 'started']);

        expect(
          await process.stdout.transform(utf8.decoder).join(),
          contains('started'),
        );
        expect(await process.stderr.transform(utf8.decoder).join(), isEmpty);
        expect(await process.exitCode, 0);
        expect(process.pid, greaterThan(0));
      });

      test('carries stdin into the started process', () async {
        const wrapper = GgProcessWrapper();
        final process = await wrapper.start(dart, [helper, 'copy']);

        process.stdin.write('through stdin');
        await process.stdin.close();

        expect(
          await process.stdout.transform(utf8.decoder).join(),
          'through stdin',
        );
        expect(await process.exitCode, 0);
      });

      test('delivers output in chunks, not in one lump', () async {
        // The regression this whole layer exists for: gg parses `dart test`
        // output per chunk, so a host that hands over the whole run at once
        // makes it read a passing run as a failure.
        const wrapper = GgProcessWrapper();
        final process = await wrapper.start(dart, [helper, 'chunks']);

        final chunks = <String>[];
        await for (final chunk in process.stdout.transform(utf8.decoder)) {
          chunks.add(chunk);
        }
        await process.exitCode;

        expect(chunks.length, greaterThan(1));
        expect(chunks.join(), 'one\ntwo\n');
      });

      test('kills a running process', () async {
        const wrapper = GgProcessWrapper();
        final process = await wrapper.start(dart, [helper, 'sleep']);

        expect(process.kill(), isTrue);
        expect(await process.exitCode, isNot(0));
      });
    });

    // #########################################################################

    group('platform', () {
      test('answers from dart:io', () {
        expect(ggPlatform.operatingSystem, Platform.operatingSystem);
        expect(ggPlatform.pathSeparator, Platform.pathSeparator);
        expect(ggPlatform.environment, isNotEmpty);
      });

      test('works with no host installed at all', () {
        // The callbacks clear `IOOverrides.global` around each call so
        // they do not route back into themselves. With nothing installed
        // there is nothing to clear, and they still answer.
        GgHost.uninstall();
        addTearDown(() => GgHost.install(GgHostIo.create()));

        expect(GgHostIo.fileSystem.currentDirectory(), isNotEmpty);
        expect(GgHostIo.fileSystem.systemTempDirectory(), isNotEmpty);
      });

      test('reads and writes the process exit code', () {
        final before = ggPlatform.exitCode;
        addTearDown(() => ggPlatform.exitCode = before);

        ggPlatform.exitCode = 5;
        expect(ggPlatform.exitCode, 5);
        expect(exitCode, 5);
      });
    });

    // #########################################################################

    // #########################################################################
    group('a started process', () {
      test('buffers output produced before a listener arrives', () async {
        // A fast program can be done before the caller registers its
        // listeners; gg reading an empty run is exactly the failure this
        // layer exists to avoid.
        final started = await GgHostIo.process.start!(dart, [
          helper,
          'emit',
          'early',
        ]);

        // Wait for the exit instead of a fixed delay: it is reported only
        // once both output streams have run dry, so by then everything the
        // program wrote sits in the buffer — on a slow Windows process
        // start just as much as on a fast one.
        final exited = Completer<int>();
        started.onExit(exited.complete);
        expect(await exited.future, 0);

        final out = StringBuffer();
        final err = StringBuffer();
        started.onStdout((chunk) => out.write(utf8.decode(chunk)));
        started.onStderr((chunk) => err.write(utf8.decode(chunk)));

        expect(out.toString(), 'early');
        expect(err.toString(), isEmpty);
        expect(started.pid, greaterThan(0));
      });

      test('buffers stderr the same way', () async {
        final started = await GgHostIo.process.start!(dart, [
          helper,
          'fail',
          'problem',
        ]);

        final exited = Completer<int>();
        started.onExit(exited.complete);
        expect(await exited.future, 3);

        final err = StringBuffer();
        started.onStdout((_) {});
        started.onStderr((chunk) => err.write(utf8.decode(chunk)));

        expect(err.toString(), 'problem');
      });

      test('writes and closes stdin, and kills', () async {
        final started = await GgHostIo.process.start!(dart, [helper, 'copy']);
        final out = StringBuffer();
        final exited = Completer<int>();
        started.onStdout((chunk) => out.write(utf8.decode(chunk)));
        started.onStderr((_) {});
        started.onExit(exited.complete);

        started.writeStdin('through stdin');
        started.closeStdin();

        expect(await exited.future, 0);
        expect(out.toString(), 'through stdin');
      });

      test('maps the signal names dart:io knows', () async {
        for (final signal in ['SIGKILL', 'SIGINT', 'SIGHUP', 'whatever']) {
          final started = await GgHostIo.process.start!(dart, [
            helper,
            'sleep',
          ]);
          final exited = Completer<int>();
          started.onStdout((_) {});
          started.onStderr((_) {});
          started.onExit(exited.complete);

          expect(started.kill(signal), isTrue);
          await exited.future;
        }
      });

      test('works with no host installed at all', () {
        // The callbacks clear `IOOverrides.global` around each call so
        // they do not route back into themselves. With nothing installed
        // there is nothing to clear, and they still answer.
        GgHost.uninstall();
        addTearDown(() => GgHost.install(GgHostIo.create()));

        expect(GgHostIo.fileSystem.currentDirectory(), isNotEmpty);
        expect(GgHostIo.fileSystem.systemTempDirectory(), isNotEmpty);
      });
    });
  });
}

// .............................................................................
/// A stand-in for the POSIX tools the process tests used to reach for.
///
/// `emit` prints its argument, `copy` pipes stdin to stdout, `chunks`
/// prints two lines with a pause between them, and `sleep` stays alive
/// long enough to be killed.
const String _helperSource = '''
import 'dart:io';

Future<void> main(List<String> args) async {
  switch (args.first) {
    case 'emit':
      stdout.write(args[1]);
    case 'copy':
      await stdout.addStream(stdin);
    case 'chunks':
      stdout.writeln('one');
      await stdout.flush();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      stdout.writeln('two');
      await stdout.flush();
    case 'fail':
      stderr.write(args[1]);
      await stderr.flush();
      exit(3);
    case 'sleep':
      await Future<void>.delayed(const Duration(seconds: 30));
  }
}
''';
