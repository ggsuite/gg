// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'dart:io';

import 'package:gg/src/tools/check_state.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late CheckState checkState;
  final messages = <String>[];
  final predecessorCalls = <String>[];

  // ...........................................................................
  void initCommand() {
    checkState = CheckState(
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
    predecessorCalls.clear();
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    initCommand();
    await setPubspec(d, version: '1.0.0');
    await commitPubspec(d);
    await addAndCommitGitIgnoreFile(d, content: gitIgnoreContent);
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
  MockCheckState mockCheckState({
    String name = 'predecessor',
    required bool success,
    String? logMessage,
    String? throwException,
    CheckState? predecessor,
  }) {
    // Create the mock
    final result = MockCheckState();

    // Mock quesetions
    when(() => result.question).thenReturn('Did $name do?');

    // Mock the get method
    final getMethod = when(
      () => result.get(
        directory: d,
        ggLog: any(named: 'ggLog'),
      ),
    );

    // Mock the predecessor
    if (predecessor != null) {
      when(() => result.predecessors).thenReturn([predecessor]);
    }

    // Throw an exception
    if (throwException != null) {
      getMethod.thenThrow(Exception(throwException));
    }

    // Succeed or fail
    else {
      getMethod.thenAnswer((invocation) {
        final ggLog =
            invocation.namedArguments[#ggLog] as void Function(String);
        if (logMessage != null) {
          ggLog(logMessage);
        }

        predecessorCalls.add(name);
        return Future.value(success);
      });
    }

    return result;
  }

  // ...........................................................................
  group('CheckState', () {
    group('exec(directory, ggLog)', () {
      group('should return true', () {
        group('and print ✓', () {
          test('when state was set to success before', () async {
            await checkState.set(directory: d, success: true);

            await checkState.exec(
              directory: d,
              ggLog: messages.add,
            );
            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('✅ Did do?'));
          });
        });
      });

      group('should throw', () {
        group('and print ❌', () {
          test('when state was set to failure before', () async {
            // Set state to false
            await checkState.set(directory: d, success: false);

            // Getting the state should throw
            await expectLater(
              checkState.exec(
                directory: d,
                ggLog: messages.add,
              ),
              throwsA(
                isA<Exception>(),
              ),
            );

            expect(messages[0], contains('⌛️ Did do?'));
            expect(messages[1], contains('❌ Did do?'));
          });

          group('when one of the predecessors', () {
            test('returns false', () async {
              // Prepare predecessors
              final predecessor0 = mockCheckState(
                name: 'predecessor0',
                success: true,
                logMessage: 'log of predecessor0',
              );

              final predecessor1 = mockCheckState(
                name: 'predecessor1',
                success: false,
                logMessage: 'log of predecessor1',
              );

              // Add predecessors to the command
              checkState = CheckState(
                name: 'run-test',
                description: 'description',
                question: 'Did do?',
                ggLog: messages.add,
                predecessors: [predecessor0, predecessor1],
              );

              // Get the state
              await expectLater(
                checkState.exec(directory: d, ggLog: messages.add),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'toString()',
                    predicate<String>(
                      (s) {
                        expect(s, contains(red('Did predecessor1 do?')));
                        expect(s, contains(darkGray('log of predecessor1')));
                        return true;
                      },
                    ),
                  ),
                ),
              );

              // Where the predecessors be called in the right order?
              expect(predecessorCalls[0], 'predecessor0');
              expect(predecessorCalls[1], 'predecessor1');
            });

            group('throws an exception', () {
              test('with a direct predecessor failing', () async {
                // Prepare predecessors xyz
                final predecessor0 = mockCheckState(
                  name: 'predecessor0',
                  success: true,
                  logMessage: 'log of predecessor0',
                  throwException: 'predecessor0 failed',
                );

                final predecessor1 = mockCheckState(
                  name: 'predecessor1',
                  success: false,
                  logMessage: 'log of predecessor1',
                );

                // Add predecessors to the command
                checkState = CheckState(
                  name: 'run-test',
                  description: 'description',
                  question: 'Did do?',
                  ggLog: messages.add,
                  predecessors: [predecessor0, predecessor1],
                );

                // Get the state
                await expectLater(
                  checkState.exec(directory: d, ggLog: messages.add),
                  throwsA(
                    isA<Exception>().having(
                      (e) => e.toString(),
                      'toString()',
                      predicate<String>(
                        (s) {
                          expect(s, contains(red('Did predecessor0 do?')));
                          expect(
                            s,
                            contains(
                              darkGray(
                                'Exception: predecessor0 failed',
                              ),
                            ),
                          );
                          return true;
                        },
                      ),
                    ),
                  ),
                );

                // Where the predecessors be called in the right order?
                expect(messages[0], contains('⌛️ Did do?'));
                expect(messages[1], contains('❌ Did do?'));

                // If one predecessor fails the process is interrupted
                expect(predecessorCalls, isEmpty);
              });

              test('with an earlier predecessor failing', () async {
                // Prepare a father predecessor, failing
                final father = mockCheckState(
                  name: 'father',
                  success: false,
                  logMessage: 'log of father',
                  throwException: 'father failed',
                );

                // Prepare a child predecessor
                final child = CheckState(
                  name: 'child',
                  description: 'description',
                  question: 'Did child do?',
                  ggLog: messages.add,
                  predecessors: [father],
                );
                await child.set(directory: d, success: true);

                // Add the child predecessor to the command
                checkState = CheckState(
                  name: 'run-test',
                  description: 'description',
                  question: 'Did do?',
                  ggLog: messages.add,
                  predecessors: [child],
                );

                // Get the state
                late String exception;
                try {
                  await checkState.exec(directory: d, ggLog: messages.add);
                } on Exception catch (e) {
                  exception = e.toString();
                }

                // If the father fails, the child should not be called
                expect(predecessorCalls, isEmpty);

                // Only the father's error message should be logged

                expect(exception, isNot(contains('Did child do?')));
                expect(exception, contains(red('Did father do?')));
                expect(
                  exception,
                  contains(darkGray('Exception: father failed')),
                );
              });
            });
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
                checkState.set(directory: d, success: true),
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
                checkState.set(directory: d, success: true),
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
              await addAndCommitGitIgnoreFile(d, content: '');

              // Try to set the state
              await expectLater(
                checkState.set(directory: d, success: true),
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
                checkState.set(directory: d, success: true),
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
            await checkState.set(directory: d, success: true);

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
            await checkState.set(directory: d, success: true);

            // The current commit hash should be in ./check.json
            final checkJson = File('${d.path}/.check.json');
            await expectLater(await checkJson.exists(), isTrue);
            final contents = json.decode(await checkJson.readAsString());
            expect(
              contents['did']['run-test']['last']['success']['hash'],
              isNotNull,
            );

            // Remove the state
            await checkState.set(directory: d, success: false);

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
                await checkState.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if .check.json is empty', () async {
            await initGit(d);
            File('${d.path}/.check.json').writeAsStringSync('{}');

            final result =
                await checkState.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if last success hash is not current hash', () async {
            // Set the state
            await checkState.set(directory: d, success: true);

            // Change the file
            await addAndCommitSampleFile(d);

            final result =
                await checkState.get(directory: d, ggLog: messages.add);
            expect(result, isFalse);
          });

          test('if one of the predecessors was not successful', () async {
            // Prepare predecessors
            final predecessor0 = mockCheckState(
              name: 'predecessor0',
              success: true,
            );

            final predecessor1 = mockCheckState(
              name: 'predecessor1',
              success: false,
            );

            // Add predecessors to the command
            checkState = CheckState(
              name: 'run-test',
              description: 'description',
              question: 'Did do?',
              ggLog: messages.add,
              predecessors: [predecessor0, predecessor1],
            );

            // Set the state to true
            await checkState.set(directory: d, success: true);

            // Get the state
            late String exception;
            try {
              await checkState.get(directory: d, ggLog: messages.add);
            } on Exception catch (e) {
              exception = e.toString();
            }
            expect(exception, contains(red('Did predecessor1 do?')));

            // Where the predecessors be called in the right order?
            expect(predecessorCalls[0], 'predecessor0');
            expect(predecessorCalls[1], 'predecessor1');
          });
        });

        group('true', () {
          group('if last success hash is current hash', () {
            test('without predecessors', () async {
              // Set the state
              await checkState.set(directory: d, success: true);

              final result =
                  await checkState.get(directory: d, ggLog: messages.add);
              expect(result, isTrue);
            });

            test('with successful predecessors', () async {
              // Prepare predecessors
              final predecessor0 = mockCheckState(
                name: 'predecessor0',
                success: true,
              );

              final predecessor1 = mockCheckState(
                name: 'predecessor1',
                success: true,
              );

              // Add predecessors to the command
              checkState = CheckState(
                name: 'run-test',
                description: 'description',
                question: 'Did do?',
                ggLog: messages.add,
                predecessors: [predecessor0, predecessor1],
              );

              // Set the state to true
              await checkState.set(directory: d, success: true);

              // Get the state
              expect(
                await checkState.get(directory: d, ggLog: messages.add),
                isTrue,
              );

              // Where the predecessors be called in the right order?
              expect(predecessorCalls[0], 'predecessor0');
              expect(predecessorCalls[1], 'predecessor1');
            });
          });
        });
      });
    });
  });
}

const gitIgnoreContent = '''
node_modules
coverage
build
*.vm.json
.DS_Store
.check.json

''';
