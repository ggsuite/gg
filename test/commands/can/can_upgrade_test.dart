// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late MockDidPublish didPublish;
  late CanUpgrade canUpgrade;
  late CommandRunner<void> runner;

  final messages = <String>[];
  final ggLog = messages.add;

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitSampleFile(d);
    registerFallbackValue(d);
    didPublish = MockDidPublish();
    canUpgrade = CanUpgrade(ggLog: ggLog, didPublish: didPublish);
    runner = CommandRunner<void>('test', 'test')..addCommand(canUpgrade);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  group('CanUpgrade', () {
    group('should throw', () {
      group('when not everything is published', () {
        for (final way in ['programmatically', 'via CLI']) {
          test(way, () async {
            didPublish.mockSuccess(success: false, directory: d, ggLog: ggLog);
            late String exception;
            try {
              if (way == 'programmatically') {
                await canUpgrade.exec(directory: d, ggLog: ggLog);
              } else {
                await runner.run(['upgrade', '-i', d.path]);
              }
            } catch (e) {
              exception = e.toString();
            }
            expect(exception, contains('❌ Published'));
          });
        }
      });
    });

    group('should succeed', () {
      group('when everything is published', () {
        for (final way in ['programmatically', 'via CLI']) {
          test(way, () async {
            didPublish.mockSuccess(success: true, directory: d, ggLog: ggLog);
            await canUpgrade.exec(directory: d, ggLog: ggLog);
            expect(messages.last, '✅ Published');
          });
        }
      });
    });

    group('special cases', () {
      test('initialized with default arguments', () {
        final canUpgrade = CanUpgrade(ggLog: ggLog);
        expect(canUpgrade.name, 'upgrade');
        expect(
          canUpgrade.description,
          'Is the package ready to get a dependeny upgrade?',
        );
      });
    });
  });
}
