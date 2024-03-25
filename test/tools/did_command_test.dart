// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg/src/tools/did_command.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late DidCommand didCommand;
  final messages = <String>[];

  // ...........................................................................
  void initCommand() {
    didCommand = DidCommand(
      name: 'run-test',
      description: 'description',
      question: 'Did do?',
      ggLog: messages.add,
      predecessors: [],
    );
    initGit(d);
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    initCommand();
    await setPubspec(d, version: '1.0.0');
    await commitPubspec(d);
    await addAndCommitGitIgnoreFile(d, content: '.check.json');
  });

  // ...........................................................................
  Future<void> removePubspec(Directory d) async {
    final pubspec = File('${d.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      pubspec.deleteSync();
    }
  }

  // ...........................................................................
  Future<void> removeGitIgnore(Directory d) async {
    final gitIgnore = File('${d.path}/.gitignore');
    if (gitIgnore.existsSync()) {
      gitIgnore.deleteSync();
    }
  }

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
            await didCommand.set(directory: d, success: true);

            final result = await didCommand.exec(
              directory: d,
              ggLog: messages.add,
            );
            expect(result, isTrue);
            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('✅ Did do?'));
          });
        });
      });

      group('should throw', () {
        group('and print ❌', () {
          test('when state was set to failure before', () async {
            // Create a failing predecessor
            final predecessor = MockDidCommand();
            when(
              () => predecessor.exec(
                directory: d,
                ggLog: any(named: 'ggLog'),
              ),
            ).thenThrow(Exception('❌ Predecessor failed'));

            // Add the predecessor to the command
            didCommand = DidCommand(
              name: 'run-test',
              description: 'description',
              question: 'Did do?',
              ggLog: messages.add,
              predecessors: [predecessor],
            );

            await expectLater(
              didCommand.exec(
                directory: d,
                ggLog: messages.add,
              ),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains('❌ Predecessor failed'),
                ),
              ),
            );

            // TODO: HIER WEITER:

            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('❌ Did do?'));
          });
        });
      });
    });

    group('set(directory, success)', () {
      group('with success', () {
        group('== true', () {
          group('should throw', () {
            test('when not everything is committed', () async {
              // Add an uncommitted file without committing
              await initUncommittedFile(d);

              // Try to set the state
              await expectLater(
                didCommand.set(directory: d, success: true),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'toString()',
                    contains('Not everything is commited.'),
                  ),
                ),
              );
            });
            test('when no .gitignore file is existing', () async {
              // Add an uncommitted file without committing
              await removeGitIgnore(d);

              // Try to set the state
              await expectLater(
                didCommand.set(directory: d, success: true),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'toString()',
                    contains('No .gitignore file found.'),
                  ),
                ),
              );
            });

            test('when .gitignore does not contain .check.json', () async {
              // Empty .gitignore
              await addAndCommitGitIgnoreFile(d, content: './test');

              // Try to set the state
              await expectLater(
                didCommand.set(directory: d, success: true),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'toString()',
                    contains('.check.json is not in .gitignore.'),
                  ),
                ),
              );
            });

            test('when directory is not a flutter or dart project', () async {
              await removePubspec(d);

              // Try to set the state
              await expectLater(
                didCommand.set(directory: d, success: true),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'toString()',
                    contains('Directory is not a flutter or dart project.'),
                  ),
                ),
              );
            });
          });

          test('should write commit hash to .check.yaml', () async {
            await addAndCommitSampleFile(d);

            // Get current hash
            final hash = await HeadHash(ggLog: messages.add).get(
              directory: d,
              ggLog: messages.add,
            );

            // Set the state
            await didCommand.set(directory: d, success: true);

            // Check the file
            final checkJson = File('${d.path}/.check.json');
            await expectLater(await checkJson.exists(), isTrue);
            final contents = json.decode(await checkJson.readAsString());
            expect(
              contents['did']['run-test']['last']['success']['hash'],
              hash,
            );
          });
        });
        group('== false', () {
          test('should remove success hash from .check.json', () async {
            await addAndCommitSampleFile(d);

            // Set the state
            await didCommand.set(directory: d, success: true);

            // The current commit hash should be in ./check.json
            final checkJson = File('${d.path}/.check.json');
            await expectLater(await checkJson.exists(), isTrue);
            final contents = json.decode(await checkJson.readAsString());
            expect(
              contents['did']['run-test']['last']['success']['hash'],
              isNotNull,
            );

            // Remove the state
            await didCommand.set(directory: d, success: false);

            // The current commit hash should not be in the file anymore
            final contentsAfter = json.decode(await checkJson.readAsString());
            expect(
              contentsAfter['did']['run-test']['last']['success']['hash'],
              isNull,
            );
          });
        });
      });
    });

    group('get(directory, ggLog)', () {
      group('should return', () {
        group('false', () {
          test('if no .check.json exists', () async {
            expect(await File('${d.path}/.check.json').exists(), isFalse);
            final result =
                await didCommand.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if .check.json is empty', () async {
            await initGit(d);
            File('${d.path}/.check.json').writeAsStringSync('{}');

            final result =
                await didCommand.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if last success hash is not current hash', () async {
            // Set the state
            await didCommand.set(directory: d, success: true);

            // Change the file
            await addAndCommitSampleFile(d);

            final result =
                await didCommand.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if one of the predecessors was not successful', () async {
            // Prepare predecessors
            final predecessor0 = MockDidCommand();
            when(() => predecessor0.exec(directory: d, ggLog: messages.add))
                .thenAnswer((_) {
              messages.add('predecessor0');
              return Future.value(false); // fails
            });

            final predecessor1 = MockDidCommand();
            when(() => predecessor1.exec(directory: d, ggLog: messages.add))
                .thenAnswer((_) {
              messages.add('predecessor1'); // fails not
              return Future.value(true);
            });

            // Add predecessors to the command
            didCommand = DidCommand(
              name: 'run-test',
              description: 'description',
              question: 'Did do?',
              ggLog: messages.add,
              predecessors: [predecessor0, predecessor1],
            );

            // Set the state to true
            await didCommand.set(directory: d, success: true);

            // Get the state
            expect(
              await didCommand.get(directory: d, ggLog: messages.add),
              isFalse, // because predecessor0 failed
            );

            // Where the predecessors be called in the right order?
            expect(messages[0], 'predecessor0');
            expect(messages[1], 'predecessor1');
          });
        });

        group('true', () {
          group('if last success hash is current hash', () {
            test('without predecessors', () async {
              // Set the state
              await didCommand.set(directory: d, success: true);

              final result =
                  await didCommand.get(directory: d, ggLog: messages.add);
              expect(result, isTrue);
            });

            test('with successful predecessors', () async {
              // Prepare predecessors
              final predecessor0 = MockDidCommand();
              when(() => predecessor0.exec(directory: d, ggLog: messages.add))
                  .thenAnswer((_) {
                messages.add('predecessor0');
                return Future.value(true);
              });

              final predecessor1 = MockDidCommand();
              when(() => predecessor1.exec(directory: d, ggLog: messages.add))
                  .thenAnswer((_) {
                messages.add('predecessor1');
                return Future.value(true);
              });

              // Add predecessors to the command
              didCommand = DidCommand(
                name: 'run-test',
                description: 'description',
                question: 'Did do?',
                ggLog: messages.add,
                predecessors: [predecessor0, predecessor1],
              );

              // Set the state to true
              await didCommand.set(directory: d, success: true);

              // Get the state
              expect(
                await didCommand.get(directory: d, ggLog: messages.add),
                isTrue,
              );

              // Where the predecessors be called in the right order?
              expect(messages[0], 'predecessor0');
              expect(messages[1], 'predecessor1');
            });
          });
        });
      });
    });
  });
}
