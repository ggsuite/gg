// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/project_detector.dart';
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

    test('returns unknown when no markers are found', () {
      expect(
        ProjectDetector.detect(workingDir: root.path),
        ProjectMode.unknown,
      );
    });
  });

  group('rewriteArgsForProjectMode', () {
    test('returns args unchanged when empty', () {
      final result = rewriteArgsForProjectMode(
        const <String>[],
        () => ProjectMode.workspace,
      );
      expect(result, isEmpty);
    });

    test('returns args unchanged when only flags are present', () {
      final result = rewriteArgsForProjectMode([
        '--help',
      ], () => ProjectMode.unknown);
      expect(result, ['--help']);
    });

    test('returns args unchanged when first command is not shared', () {
      final result = rewriteArgsForProjectMode([
        'run',
        '--port',
        '8080',
      ], () => ProjectMode.unknown);
      expect(result, ['run', '--port', '8080']);
    });

    test('prefixes "multi" for shared command in workspace mode', () {
      final result = rewriteArgsForProjectMode([
        'do',
        'commit',
        '-m',
        'msg',
      ], () => ProjectMode.workspace);
      expect(result, ['multi', 'do', 'commit', '-m', 'msg']);
    });

    test('prefixes "one" for shared command in single mode', () {
      final result = rewriteArgsForProjectMode([
        'can',
        'commit',
      ], () => ProjectMode.single);
      expect(result, ['one', 'can', 'commit']);
    });

    test('preserves leading flags before shared command', () {
      final result = rewriteArgsForProjectMode([
        '--verbose',
        'did',
        'push',
      ], () => ProjectMode.workspace);
      expect(result, ['--verbose', 'multi', 'did', 'push']);
    });

    test('throws StateError with helpful message in unknown mode', () {
      expect(
        () => rewriteArgsForProjectMode([
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
              contains('gg multi do'),
            ),
          ),
        ),
      );
    });
  });
}
