// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/project_detector.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('project_detector_test');
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  group('ProjectDetector.detect', () {
    test('returns workspace when .master folder is found at root', () {
      Directory(path.join(root.path, '.master')).createSync();
      expect(
        ProjectDetector.detect(workingDir: root.path),
        ProjectMode.workspace,
      );
    });

    test('returns workspace when tickets folder is found at root', () {
      Directory(path.join(root.path, 'tickets')).createSync();
      expect(
        ProjectDetector.detect(workingDir: root.path),
        ProjectMode.workspace,
      );
    });

    test('returns workspace when an ancestor contains .master', () {
      Directory(path.join(root.path, '.master')).createSync();
      final sub = Directory(path.join(root.path, 'sub', 'deep'))
        ..createSync(recursive: true);
      expect(
        ProjectDetector.detect(workingDir: sub.path),
        ProjectMode.workspace,
      );
    });

    test('returns single for a pubspec.yaml', () {
      File(path.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      expect(ProjectDetector.detect(workingDir: root.path), ProjectMode.single);
    });

    test('returns single for a package.json', () {
      File(path.join(root.path, 'package.json')).writeAsStringSync('{}');
      expect(ProjectDetector.detect(workingDir: root.path), ProjectMode.single);
    });

    test('returns single for a tsconfig.json', () {
      File(path.join(root.path, 'tsconfig.json')).writeAsStringSync('{}');
      expect(ProjectDetector.detect(workingDir: root.path), ProjectMode.single);
    });

    test('returns single when marker is in an ancestor', () {
      File(path.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      final sub = Directory(path.join(root.path, 'lib', 'src'))
        ..createSync(recursive: true);
      expect(ProjectDetector.detect(workingDir: sub.path), ProjectMode.single);
    });

    test('workspace takes precedence over single-project markers', () {
      Directory(path.join(root.path, '.master')).createSync();
      File(path.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      expect(
        ProjectDetector.detect(workingDir: root.path),
        ProjectMode.workspace,
      );
    });

    test('returns single for a repo checked out inside .master', () {
      // .master/<repo> lives inside the master workspace, but the repo
      // itself is a standalone project, not part of a ticket.
      Directory(path.join(root.path, 'tickets')).createSync();
      final repo = Directory(path.join(root.path, '.master', 'gg_dna'))
        ..createSync(recursive: true);
      File(path.join(repo.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      expect(ProjectDetector.detect(workingDir: repo.path), ProjectMode.single);
    });

    test('returns unknown inside .master without project markers', () {
      final master = Directory(path.join(root.path, '.master'))..createSync();
      expect(
        ProjectDetector.detect(workingDir: master.path),
        ProjectMode.unknown,
      );
    });

    test('returns unknown when no markers are found', () {
      expect(
        ProjectDetector.detect(workingDir: root.path),
        ProjectMode.unknown,
      );
    });
  });

  group('checkArgsForProjectMode', () {
    test('returns args unchanged when empty', () {
      final result = checkArgsForProjectMode(
        const <String>[],
        () => ProjectMode.workspace,
      );
      expect(result, isEmpty);
    });

    test('returns args unchanged when only flags are present', () {
      final result = checkArgsForProjectMode([
        '--help',
      ], () => ProjectMode.unknown);
      expect(result, ['--help']);
    });

    test('returns args unchanged for mode-independent commands', () {
      for (final command in modeIndependentCommands) {
        final result = checkArgsForProjectMode([
          command,
          'can',
          'commit',
        ], () => ProjectMode.unknown);
        expect(result, [command, 'can', 'commit']);
      }
    });

    test('returns args unchanged in workspace mode', () {
      final result = checkArgsForProjectMode([
        'do',
        'commit',
        '-m',
        'msg',
      ], () => ProjectMode.workspace);
      expect(result, ['do', 'commit', '-m', 'msg']);
    });

    test('asks to use "gg one" in single mode', () {
      expect(
        () => checkArgsForProjectMode([
          'can',
          'commit',
        ], () => ProjectMode.single),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains(yellow('This is a standalone project. Please use')),
              contains(blue('gg one can commit')),
              contains(yellow('instead.')),
            ),
          ),
        ),
      );
    });

    test('keeps leading flags in the "gg one" hint', () {
      expect(
        () => checkArgsForProjectMode([
          '--verbose',
          'did',
          'push',
        ], () => ProjectMode.single),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(blue('gg --verbose one did push')),
          ),
        ),
      );
    });

    test('throws StateError with helpful message in unknown mode', () {
      expect(
        () => checkArgsForProjectMode([
          'do',
          'commit',
        ], () => ProjectMode.unknown),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Cannot run "gg do" here'),
              contains('gg one do'),
              contains('gg ticket workspace'),
            ),
          ),
        ),
      );
    });
  });
}
