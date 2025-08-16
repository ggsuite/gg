// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/tools/did_command.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late DidCommand didCommand;
  final messages = <String>[];

  // ...........................................................................
  void initDidCommand() {
    didCommand = DidCommand(
      name: 'do',
      description: 'description',
      shortDescription: 'Did do?',
      suggestion: 'Please run »gg do«.',
      ggLog: messages.add,
      stateKey: 'did-do',
    );
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    await addAndCommitSampleFile(d);
    initDidCommand();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('DidCommand', () {
    group('exec(directory, ggLog)', () {
      group('should return true', () {
        group('and print ✓', () {
          test('when state was set to success before', () async {
            await didCommand.state.writeSuccess(directory: d, key: 'did-do');

            await didCommand.exec(directory: d, ggLog: messages.add);
            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('✅ Did do?'));
          });
        });
      });

      group('should throw', () {
        group('and print ❌', () {
          test('when state was not set to success before', () async {
            // Getting the state should throw
            late String exceptionMessage;

            try {
              await didCommand.exec(directory: d, ggLog: messages.add);
            } catch (e) {
              exceptionMessage = e.toString();
            }

            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('❌ Did do?'));
            expect(
              exceptionMessage,
              contains(
                '${darkGray('Please run ')}${blue('gg do')}${darkGray('.')}',
              ),
            );
          });
        });
      });
    });

    group('get(directory, ggLog)', () {
      group('should return', () {
        group('false', () {
          test('if something has changed inbetween', () async {
            await didCommand.state.writeSuccess(directory: d, key: 'did-do');

            await addAndCommitSampleFile(
              d,
              fileName: 'another-file.txt',
              content: 'another content',
            );

            final success = await didCommand.get(
              directory: d,
              ggLog: messages.add,
            );

            expect(success, isFalse);
          });
        });

        group('true', () {
          test(
            'if a success state was saved and nothing has changed',
            () async {
              await didCommand.state.writeSuccess(directory: d, key: 'did-do');

              final success = await didCommand.get(
                directory: d,
                ggLog: messages.add,
              );

              expect(success, isTrue);
            },
          );

          test(
            'if an unstaged file exists and ignoreUnstaged is true',
            () async {
              // Write success
              await didCommand.state.writeSuccess(directory: d, key: 'did-do');

              final success = await didCommand.get(
                directory: d,
                ggLog: messages.add,
              );

              expect(success, isTrue);

              // Add a file without committing
              await addFileWithoutCommitting(d);

              final success2 = await didCommand.get(
                directory: d,
                ggLog: messages.add,
                ignoreUnstaged: true,
              );

              // Success is true, because ignoreUnstaged is true
              expect(success2, isTrue);

              final success3 = await didCommand.get(
                directory: d,
                ggLog: messages.add,
                ignoreUnstaged: false,
              );

              // Success is false, because ignoreUnstaged is false
              expect(success3, isFalse);
            },
          );
        });
      });
    });

    group('set(directory, ggLog)', () {
      test('should set the state to success', () async {
        await didCommand.set(directory: d);

        final success = await didCommand.get(directory: d, ggLog: messages.add);

        expect(success, isTrue);
      });
    });
  });
}
