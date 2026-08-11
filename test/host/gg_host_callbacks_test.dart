// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The shapes an embedder fills in. What gg does with them once they are
// installed is `gg_host_test.dart`'s subject; this file is about the
// contract itself.

import 'dart:typed_data';

import 'package:gg/gg.dart';
import 'package:test/test.dart';

void main() {
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

  // ###########################################################################
  group('GgEntityType', () {
    test('names the four things a path can be', () {
      // Mirrors FileSystemEntityType without depending on it, so an
      // embedder can answer with a plain value.
      expect(GgEntityType.values, hasLength(4));
      expect(
        GgEntityType.values.map((e) => e.name),
        containsAll(['notFound', 'file', 'directory', 'link']),
      );
    });
  });

  // ###########################################################################
  group('GgProcessOutcome', () {
    test('carries what a finished program left behind', () {
      const outcome = GgProcessOutcome(
        exitCode: 2,
        stdout: 'out',
        stderr: 'err',
        pid: 7,
      );

      expect(outcome.exitCode, 2);
      expect(outcome.stdout, 'out');
      expect(outcome.stderr, 'err');
      expect(outcome.pid, 7);
    });

    test('reports no pid when the host does not know one', () {
      const outcome = GgProcessOutcome(exitCode: 0, stdout: '', stderr: '');
      expect(outcome.pid, 0);
    });
  });

  // ###########################################################################
  group('GgProcessCallbacks', () {
    test('can be built without a streaming start', () {
      // Then gg runs the program to completion and replays its output —
      // enough for a caller that reads the output at the end, but not for
      // `can commit`, which parses `dart test` line by line.
      final callbacks = GgProcessCallbacks(
        run:
            (
              executable,
              arguments, {
              workingDirectory,
              environment,
              includeParentEnvironment = true,
              runInShell = false,
            }) async =>
                const GgProcessOutcome(exitCode: 0, stdout: '', stderr: ''),
      );

      expect(callbacks.start, isNull);
    });
  });

  // ###########################################################################
  group('GgPlatformCallbacks', () {
    test('exposes every callback it was built with', () {
      var recorded = -1;
      final callbacks = GgPlatformCallbacks(
        environment: () => const {'A': '1'},
        operatingSystem: () => 'linux',
        pathSeparator: () => '/',
        setExitCode: (code) => recorded = code,
        exitCode: () => recorded,
      );

      expect(callbacks.environment(), {'A': '1'});
      expect(callbacks.operatingSystem(), 'linux');
      expect(callbacks.pathSeparator(), '/');
      callbacks.setExitCode(3);
      expect(callbacks.exitCode(), 3);
    });
  });

  // ###########################################################################
  group('GgPromptCallbacks', () {
    test('answers asynchronously, unlike the file system', () async {
      // A prompt has no reason to be synchronous — every caller in gg
      // awaits it — and demanding it would force an embedder to block on
      // its input, which not every platform allows.
      final callbacks = GgPromptCallbacks(
        select: (prompt, options, initialIndex) async => options.length - 1,
        input: (prompt, defaultValue, initialText, asMessageEditor) async =>
            'answered',
      );

      expect(await callbacks.select('Pick', ['a', 'b'], 0), 1);
      expect(await callbacks.input('Say', '', '', false), 'answered');
    });
  });
}
