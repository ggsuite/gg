// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late CommandRunner<void> runner;
  late DoMaintain doMaintain;

  late MockDoUpgrade doUpgrade;
  late MockDidPublish didPublish;

  // ...........................................................................
  void mockDoUpgrade({required bool success, bool majorVersions = false}) {
    doUpgrade.mockGet(
      result: null,
      doThrow: !success,
      directory: d,
      majorVersions: majorVersions,
      ggLog: null,
    );
  }

  void mockDidPublish({required bool success}) {
    didPublish.mockExec(
      result: success,
      directory: d,
      ggLog: ggLog,
      doThrow: !success,
    );
  }

  // ...........................................................................
  void initMocks() {
    doUpgrade = MockDoUpgrade();
    mockDoUpgrade(success: true);

    didPublish = MockDidPublish();
    mockDidPublish(success: true);
  }

  // ...........................................................................
  setUp(() async {
    d = await Directory.systemTemp.createTemp();
    registerFallbackValue(d);

    initMocks();

    doMaintain = DoMaintain(
      ggLog: ggLog,
      doUpgrade: doUpgrade,
      didPublish: didPublish,
    );

    runner = CommandRunner<void>('gg', 'gg')..addCommand(doMaintain);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  group('DoMaintain', () {
    group('- main case', () {
      group('- should upgrade dependencies and check if published', () {
        group('- should upgrade dependencies and check if published', () {
          tearDown(() {
            expect(messages[0], contains('⌛️ Upgrading dependencies'));
            expect(messages[1], contains('✅ Upgrading dependencies'));
            expect(messages[2], contains('✅ DidPublish'));
          });

          test('- programmatically', () async {
            await doMaintain.exec(directory: d, ggLog: ggLog);
          });
          test('- via CLI', () async {
            await runner.run(['maintain', '-i', d.path]);
          });
        });
      });
    });

    group('- edge cases', () {
      test('- should init with defaults', () {
        final doMaintain = DoMaintain(ggLog: ggLog);

        expect(doMaintain.name, 'maintain');
        expect(
          doMaintain.description,
          'Is the package upgraded and published?',
        );
      });

      test('- should throw on upgrade failure', () async {
        mockDoUpgrade(success: false);

        expect(
          () => doMaintain.exec(directory: d, ggLog: ggLog),
          throwsA(isA<Exception>()),
        );
      });

      test('- should throw on publish failure', () async {
        mockDidPublish(success: false);

        expect(
          () => doMaintain.exec(directory: d, ggLog: ggLog),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
