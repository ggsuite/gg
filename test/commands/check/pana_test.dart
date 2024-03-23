// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  late GgProcessWrapper processWrapper;
  late Pana pana;
  late CommandRunner<void> runner;
  late Directory d;

  // ...........................................................................
  setUp(() async {
    messages.clear();
    processWrapper = MockGgProcessWrapper();
    pana = Pana(ggLog: messages.add, processWrapper: processWrapper);
    runner = CommandRunner('test', 'test')..addCommand(pana);
    d = await Directory.systemTemp.createTemp('gg_check_test');
  });

  // ...........................................................................
  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  void mockJsonResult(String json) {
    when(
      () => processWrapper.run(
        'dart',
        ['run', 'pana', '--no-warning', '--json', '--no-dartdoc'],
        workingDirectory: d.path,
      ),
    ).thenAnswer((_) async => ProcessResult(0, 0, json, ''));
  }

  // ...........................................................................
  group('Pana', () {
    // .........................................................................
    group('should throw an Exception', () {
      test('when pana returns invalid JSON', () async {
        // Mock process returning invalid JSON
        mockJsonResult('{"foo": "bar"');

        // Running process should throw an exception
        await expectLater(
          runner.run(['pana', '--input', d.path]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString()',
              contains('"dart run pana" failed. See log for details.'),
            ),
          ),
        );

        // Check result
        expect(messages[0], contains('⌛️ Running "dart pana"'));
        expect(messages[1], contains('❌ Running "dart pana"'));
        expect(
          messages[2],
          contains('FormatException: Unexpected end of input'),
        );
      });
    });

    // .........................................................................
    group('should succeed', () {
      test('when 140 pubpoints are reached', () async {
        // Mock an success report
        final successReport =
            File('test/data/pana_success_report.json').readAsStringSync();
        mockJsonResult(successReport);

        // Run pana
        await runner.run(['pana', '--input', d.path]);

        // Check result
        expect(messages[0], contains('⌛️ Running "dart pana"'));
        expect(messages[1], contains('✅ Running "dart pana"'));
      });

      // .......................................................................
      test('should fail when 140 pubpoints are not reached', () async {
        // Mock an success report
        final notSuccessReport =
            File('test/data/pana_not_success_report.json').readAsStringSync();
        mockJsonResult(notSuccessReport);

        // Run pana
        await expectLater(
          runner.run(['pana', '--input', d.path]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString()',
              contains('"dart run pana" failed. See log for details.'),
            ),
          ),
        );

        // Check result
        expect(messages[0], contains('⌛️ Running "dart pana"'));
        expect(messages[1], contains('❌ Running "dart pana"'));
        expect(
          messages[2],
          contains('$red[x] 0/10 points: Provide a valid `pubspec.yaml`'),
        );
        expect(
          messages[2],
          contains(
            '$brightBlack* `pubspec.yaml` doesn\'t have a `homepage` entry.',
          ),
        );
      });
    });
  });
}
