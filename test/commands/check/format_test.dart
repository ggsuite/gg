// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_is_github/gg_is_github.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  late CommandRunner<void> runner;
  late Directory tmpDir;

  // ...........................................................................
  setUp(() {
    testIsGitHub = false;
    messages.clear();
    runner = CommandRunner<void>('test', 'test');
    final format = Format(log: messages.add);
    runner.addCommand(format);
    tmpDir = Directory.systemTemp.createTempSync();
  });

  // ...........................................................................
  tearDown(() {
    tmpDir.deleteSync(recursive: true);
    testIsGitHub = null;
  });

  // ...........................................................................
  Future<void> createSampleFiles() async {
    final file = File(join(tmpDir.path, 'test.dart'));
    file.writeAsStringSync(fooWithFormattingError);

    final subDir = Directory(join(tmpDir.path, 'sub'));
    await subDir.create();
    final file1 = File(join(subDir.path, 'test1.dart'));
    file1.writeAsStringSync(fooWithFormattingError);
  }

  group('Format', () {
    group('run()', () {
      // .......................................................................
      group('should print a usage description', () {
        test('when called with args=[--help]', () async {
          await capturePrint(
            log: messages.add,
            code: () => runner.run(
              ['format', '--help'],
            ),
          );

          expect(
            messages.last,
            contains('Runs »dart format«.'),
          );
        });
      });

      // .......................................................................
      group('should throw', () {
        test('if input is missing', () async {
          await expectLater(
            runner.run(
              ['format', '--input=some-unknown-dir'],
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Directory "some-unknown-dir" does not exist.'),
              ),
            ),
          );
        });

        group('if formatting errors are int the code', () {
          group('and test are running', () {
            test('on GitHub', () async {
              testIsGitHub = true;

              await createSampleFiles();

              // Run the command
              await expectLater(
                () => runner.run(
                  ['format', '--input', tmpDir.path],
                ),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'message',
                    contains('Exception: dart format failed.'),
                  ),
                ),
              );

              // An error should have been logged
              expect(messages[0], contains('⌛️ Running "dart format"'));
              expect(messages[1], contains('❌ Running "dart format"'));
            });

            test('locally', () async {
              testIsGitHub = false;

              await createSampleFiles();

              // Run the command
              await runner.run(['format', '--input', tmpDir.path]);

              // An error should have been logged
              expect(messages[0], contains('⌛️ Running "dart format"'));
              expect(messages[1], contains('✅ Running "dart format"'));
            });
          });
        });

        test('if dart format does exit with error', () async {
          // Create a mock process wrapper
          final processWrapper = MockGgProcessWrapper();

          // Configure runner and command
          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(
            Format(
              log: messages.add,
              processWrapper: processWrapper,
            ),
          );

          // Make process wrapper returning an error
          when(
            () => processWrapper.run(
              any(),
              any(),
              workingDirectory: any(named: 'workingDirectory'),
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(1, 1, 'stdout', 'stderr'),
            ),
          );

          // Run the command
          await expectLater(
            () => runner.run(
              ['format', tmpDir.path],
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Exception: dart format failed.'),
              ),
            ),
          );

          // An error should have been logged
          expect(messages[0], contains('⌛️ Running "dart format"'));
          expect(messages[1], contains('❌ Running "dart format"'));
        });
      });

      // .......................................................................
      group('should succeed', () {
        group('when called with right input param', () {
          test('and no format errors in code', () async {
            await runner.run(['format', '--input', tmpDir.path]);
            expect(messages[0], contains('⌛️ Running "dart format"'));
            expect(messages[1], contains('✅ Running "dart format"'));
          });
        });
      });
    });
  });
}

// .............................................................................
const fooWithFormattingError = '''
  void foo() {
  print('Hello, World!');
}
''';
