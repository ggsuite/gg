// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/*import 'dart:convert';

import 'dart:io';

import 'package:gg/src/tools/check_state.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:test/test.dart';*/

// HIER WEITER: TESTS FÜR CHECK_STATE FERTIG SCHREIBEN

void main() {
  /* late Directory d;
  late CheckState checkState;
  final messages = <String>[];

  // ...........................................................................
  void initCommand() {
    checkState = CheckState(
      ggLog: messages.add,
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
  });

  // ...........................................................................
  Future<void> removePubspec(Directory d) async {
    final pubspec = File('${d.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      pubspec.deleteSync();
    }
  }

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('CheckState', () {
    group('writeSuccess(directory, success)', () {
      group('with success', () {
        group('should throw', () {
          test('when not everything is committed', () async {
            // Add an uncommitted file without committing
            await initUncommittedFile(d);

            // Try to set the state
            await expectLater(
              checkState.writeSuccess(directory: d, success: true),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains('Not everything is commited.'),
                ),
              ),
            );
          });
          test('when directory is not a flutter or dart project', () async {
            await removePubspec(d);

            // Try to set the state
            await expectLater(
              checkState.writeSuccess(directory: d, success: true),
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
          await checkState.writeSuccess(directory: d, success: true);

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
    });

    group('readSuccess(directory, stage, ggLog)', () {
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
            await checkState.writeSuccess(directory: d, success: true);

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
            await checkState.writeSuccess(directory: d, success: true);

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
              await checkState.writeSuccess(directory: d, success: true);

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
              await checkState.writeSuccess(directory: d, success: true);

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
  });*/
}
