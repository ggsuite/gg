// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late MockDidPublish didPublish;
  late MockIsUpgraded isUpgraded;
  late DidUpgrade didUpgrade;
  late CommandRunner<void> runner;

  final messages = <String>[];
  final ggLog = messages.add;

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    registerFallbackValue(d);
    didPublish = MockDidPublish();
    isUpgraded = MockIsUpgraded();
    didUpgrade = DidUpgrade(
      ggLog: ggLog,
      didPublish: didPublish,
      isUpgraded: isUpgraded,
    );
    runner = CommandRunner<void>('test', 'test')..addCommand(didUpgrade);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  group('DidUpgrade', () {
    group('should check', () {
      group('if everything is upgraded and published', () {
        for (final viaCli in [
          true,
          false,
        ]) {
          test(viaCli ? 'via CLI' : 'programmatically', () async {
            didPublish.mockSuccess(success: true, directory: d, ggLog: ggLog);
            isUpgraded.mockSuccess(success: true, directory: d, ggLog: ggLog);

            if (viaCli == false) {
              await didUpgrade.exec(directory: d, ggLog: ggLog);
            } else {
              await runner.run(['upgrade', '-i', d.path]);
            }
            expect(messages[0], '✅ Upgraded');
            expect(messages[1], '✅ Published');
          });
        }
      });
    });

    group('should handle special cases: ', () {
      test('instantiate without optional parameters', () {
        expect(
          () => DidUpgrade(ggLog: ggLog),
          returnsNormally,
        );
      });
    });
  });
}
