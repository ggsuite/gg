// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gg/gg.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_is_github/gg_is_github.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

import 'in_memory_host.dart';

void main() {
  tearDown(GgHost.uninstall);

  group('GgHost', () {
    // #########################################################################
    group('install(host)', () {
      test('routes dart:io through the file system callbacks', () {
        final host = InMemoryHost()..writeFile('/work/hello.txt', 'Hello Host');
        GgHost.install(host.ggHost);

        expect(File('/work/hello.txt').existsSync(), isTrue);
        expect(File('/work/hello.txt').readAsStringSync(), 'Hello Host');
        expect(File('/work/missing.txt').existsSync(), isFalse);
        expect(Directory('/work').existsSync(), isTrue);
      });

      test('routes relative paths through the callbacks working dir', () {
        final host = InMemoryHost()..writeFile('/work/rel.txt', 'relative');
        GgHost.install(host.ggHost);

        expect(Directory.current.path, '/work');
        expect(File('rel.txt').readAsStringSync(), 'relative');
        expect(File('rel.txt').absolute.path, '/work/rel.txt');
        // `.`, like dart:io — `parent` keeps the caller's spelling.
        expect(File('rel.txt').parent.path, '.');
        expect(File('rel.txt').absolute.parent.path, '/work');
      });

      test('streams a started process through the host', () async {
        final host = InMemoryHost()
          ..stubProcess(
            'dart test',
            exitCode: 0,
            stdout: 'first\nsecond\nthird',
          );
        GgHost.install(host.ggHost);

        const wrapper = GgProcessWrapper();
        final process = await wrapper.start('dart', ['test']);

        // One event per line, not one event for the whole run — gg's test
        // output parser depends on it.
        final chunks = <String>[];
        await for (final chunk in process.stdout.transform(utf8.decoder)) {
          chunks.add(chunk);
        }

        expect(chunks, ['first\n', 'second\n', 'third\n']);
        expect(await process.exitCode, 0);
      });

      test('carries what gg types into a started process\' stdin', () async {
        final host = InMemoryHost()..stubProcess('dart pub publish');
        GgHost.install(host.ggHost);

        const wrapper = GgProcessWrapper();
        final process = await wrapper.start('dart', ['pub', 'publish']);
        process.stdin.writeln('y');
        await process.stdin.close();
        await process.exitCode;

        expect(host.startedProcess!.stdinBuffer.toString(), 'y\n');
        expect(host.startedProcess!.stdinClosed, isTrue);
      });

      test('forwards kill to the host', () async {
        final host = InMemoryHost()..stubProcess('sleep 10');
        GgHost.install(host.ggHost);

        const wrapper = GgProcessWrapper();
        final process = await wrapper.start('sleep', ['10']);

        expect(process.kill(), isTrue);
        expect(host.startedProcess!.killedWith, contains('SIGTERM'));
        expect(process.pid, isA<int>());
      });

      test('replays the output when the host cannot stream', () async {
        // A host without a `start` callback: gg runs the program to
        // completion and hands the output over afterwards.
        final host = InMemoryHost()..stubProcess('git log', stdout: 'one\ntwo');
        GgHost.install(
          GgHost(
            fileSystem: host.ggHost.fileSystem,
            process: GgProcessCallbacks(run: host.process.run),
            platform: host.ggHost.platform,
            console: host.ggHost.console,
          ),
        );

        const wrapper = GgProcessWrapper();
        final process = await wrapper.start('git', ['log']);

        expect(await process.stdout.transform(utf8.decoder).join(), 'one\ntwo');
        expect(await process.exitCode, 0);
        expect(process.kill(), isFalse);
        expect(() => process.stdin.writeln('ignored'), returnsNormally);
      });

      test('routes process execution through the process callbacks', () async {
        final host = InMemoryHost()
          ..stubProcess('git status', exitCode: 0, stdout: 'clean');
        GgHost.install(host.ggHost);

        const wrapper = GgProcessWrapper();
        final result = await wrapper.run('git', ['status']);

        expect(result.exitCode, 0);
        expect(result.stdout, 'clean');
        expect(host.processCalls, ['git status']);
      });

      test('routes Platform questions through the platform callbacks', () {
        final host = InMemoryHost(
          environment: {'GG': '1'},
          operatingSystem: 'windows',
        );
        GgHost.install(host.ggHost);

        expect(ggPlatform.environment, {'GG': '1'});
        expect(ggPlatform.operatingSystem, 'windows');
        expect(ggPlatform.isWindows, isTrue);
        expect(ggPlatform.pathSeparator, r'\');
      });

      test('routes stdout and stderr through the console callbacks', () {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        stdout.write('out');
        stdout.writeln('-line');
        stderr.writeln('err');

        expect(host.stdoutBuffer.toString(), 'out-line\n');
        expect(host.stderrBuffer.toString(), 'err\n');
      });

      test('routes the exit code through the platform callbacks', () {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        ggExitCode = 3;
        expect(host.exitCode, 3);
        expect(ggExitCode, 3);
      });

      test('turns exit(code) into a GgExitException', () {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        expect(
          () => exit(7),
          throwsA(
            isA<GgExitException>()
                .having((e) => e.code, 'code', 7)
                .having((e) => e.toString(), 'toString', contains('7')),
          ),
        );
        expect(host.exitCode, 7);
      });

      test('honors a custom onExit callback', () {
        final host = InMemoryHost();
        var seen = -1;
        GgHost.install(
          GgHost(
            fileSystem: host.ggHost.fileSystem,
            process: host.ggHost.process,
            platform: host.ggHost.platform,
            console: host.ggHost.console,
            onExit: (code) {
              seen = code;
              throw StateError('exited');
            },
          ),
        );

        expect(() => exit(9), throwsStateError);
        expect(seen, 9);
      });

      test('disables colors when the host has no ansi terminal', () {
        GgHost.install(InMemoryHost().ggHost);
        expect(ggColorsEnabled, isFalse);
      });

      test('enables colors when the host supports ansi escapes', () {
        GgHost.install(InMemoryHost(supportsAnsiEscapes: true).ggHost);
        expect(ggColorsEnabled, isTrue);
      });

      test('keeps colors off when NO_COLOR is set', () {
        GgHost.install(
          InMemoryHost(
            supportsAnsiEscapes: true,
            environment: {'NO_COLOR': '1'},
          ).ggHost,
        );
        expect(ggColorsEnabled, isFalse);
      });

      test('keeps colors off on a dumb terminal', () {
        GgHost.install(
          InMemoryHost(
            supportsAnsiEscapes: true,
            environment: {'TERM': 'dumb'},
          ).ggHost,
        );
        expect(ggColorsEnabled, isFalse);
      });

      test('tells gg_is_github about the host environment', () {
        GgHost.install(
          InMemoryHost(environment: {'GITHUB_ACTIONS': 'true'}).ggHost,
        );
        expect(isGitHub, isTrue);

        GgHost.install(InMemoryHost().ggHost);
        expect(isGitHub, isFalse);
      });

      test('is remembered in GgHost.installed', () {
        expect(GgHost.installed, isNull);
        final host = InMemoryHost().ggHost;
        GgHost.install(host);
        expect(GgHost.installed, host);
      });
    });

    // #########################################################################
    group('uninstall()', () {
      test('gives dart:io back', () {
        GgHost.install(InMemoryHost().ggHost);
        expect(Directory.current.path, '/work');

        GgHost.uninstall();
        expect(GgHost.installed, isNull);
        expect(Directory.current.path, isNot('/work'));
        expect(GgProcessDelegate.current, GgProcessDelegate.defaultDelegate);
        expect(GgPlatformDelegate.current, GgPlatformDelegate.defaultDelegate);
      });
    });

    // #########################################################################
    group('runGg()', () {
      test('runs the whole gg CLI through an in-memory host', () async {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        final messages = <String>[];
        final code = await runGg(args: ['--version'], ggLog: messages.add);

        expect(code, 0);
        expect(messages, [ggVersion]);
      });

      test('reports errors through ggLog and keeps the exit code', () async {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        final messages = <String>[];
        final code = await runGg(
          args: ['--unknown-flag'],
          ggLog: messages.add,
          detectMode: () => ProjectMode.workspace,
        );

        expect(messages, isNotEmpty);
        expect(code, 1);
      });

      test('detects the project mode from the host file system', () async {
        final host = InMemoryHost()..writeFile('/work/pubspec.yaml', 'name: x');
        GgHost.install(host.ggHost);

        final messages = <String>[];
        await runGg(args: ['do', 'commit'], ggLog: messages.add);

        expect(messages.join('\n'), contains('standalone project'));
      });

      test('reports »not a workspace« when nothing is detected', () async {
        GgHost.install(InMemoryHost().ggHost);

        final messages = <String>[];
        await runGg(args: ['do', 'commit'], ggLog: messages.add);

        expect(messages.join('\n'), contains('Not a workspace'));
      });

      test('returns the code of a GgExitException', () async {
        final host = InMemoryHost();
        GgHost.install(host.ggHost);

        final messages = <String>[];
        final code = await runGg(
          args: ['do', 'commit'],
          ggLog: messages.add,
          detectMode: () => throw const GgExitException(42),
        );

        expect(code, 42);
      });
    });
  });

  // ###########################################################################
  group('GgHostUnsupportedError', () {
    test('names what is missing', () {
      final error = GgHostUnsupportedError('Watching /a');
      expect(error.message, contains('Watching /a'));
      expect(error.message, contains('GgHost.install'));
    });
  });

  // ###########################################################################
  group('ggProcessResultFrom(outcome)', () {
    test('copies every field', () {
      final result = ggProcessResultFrom(
        const GgProcessOutcome(exitCode: 2, stdout: 'o', stderr: 'e', pid: 123),
      );
      expect(result.exitCode, 2);
      expect(result.stdout, 'o');
      expect(result.stderr, 'e');
      expect(result.pid, 123);
    });
  });

  // ###########################################################################
  group('GgDirectoryEntry', () {
    test('prints path and type', () {
      const entry = GgDirectoryEntry(
        path: '/a/b',
        type: GgEntityType.directory,
      );
      expect(entry.toString(), '/a/b (directory)');
    });
  });

  // ###########################################################################
  group('GgConsoleCallbacks', () {
    test('defaults to a non-terminal 80 column console', () {
      final callbacks = GgConsoleCallbacks(
        writeStdout: (_) {},
        writeStderr: (_) {},
      );
      expect(callbacks.hasTerminal(), isFalse);
      expect(callbacks.supportsAnsiEscapes(), isFalse);
      expect(callbacks.terminalColumns(), 80);
      expect(callbacks.readLine, isNull);
    });
  });

  // ###########################################################################
  group('GgFileSystemCallbacks', () {
    test('exposes every callback it was built with', () {
      final callbacks = GgFileSystemCallbacks(
        typeOf: (_, _) => GgEntityType.notFound,
        readBytes: (_) => Uint8List(0),
        writeBytes: (_, _, _) {},
        createDirectory: (_, _) {},
        createFile: (_, _) {},
        deleteEntity: (_, _) {},
        listDirectory: (_, _) => [],
        rename: (_, _) {},
        copyFile: (_, _) {},
        currentDirectory: () => '/',
        setCurrentDirectory: (_) {},
        systemTempDirectory: () => '/tmp',
        createTempDirectory: (_, _) => '/tmp/x',
        resolveSymbolicLinks: (path) => path,
        createLink: (_, _) {},
        linkTarget: (_) => '/target',
      );

      expect(callbacks.typeOf('/a', true), GgEntityType.notFound);
      expect(callbacks.currentDirectory(), '/');
      expect(callbacks.systemTempDirectory(), '/tmp');
      expect(callbacks.createTempDirectory('/tmp', 'p'), '/tmp/x');
      expect(callbacks.resolveSymbolicLinks('/a'), '/a');
      expect(callbacks.linkTarget('/l'), '/target');
      expect(callbacks.readBytes('/a'), isEmpty);
      expect(callbacks.listDirectory('/a', false), isEmpty);
    });
  });
}
