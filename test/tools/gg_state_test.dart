// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'dart:io';

import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late GgState ggState;
  final messages = <String>[];

  // ...........................................................................
  void initCommand() {
    ggState = GgState(
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
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('CheckState', () {
    group('writeSuccess(directory, success)', () {
      group('with success == true', () {
        test('should write last change hash to .gg.json', () async {
          await addAndCommitSampleFile(d);

          // Get last changes hash
          final hash = await LastChangesHash(ggLog: messages.add).get(
            directory: d,
            ggLog: messages.add,
          );

          // Set the state
          await ggState.writeSuccess(
            directory: d,
            key: 'can-commit',
          );

          // Check the file
          final checkJson = File('${d.path}/.gg.json');
          await expectLater(await checkJson.exists(), isTrue);
          final contentsString = await checkJson.readAsString();
          final contents = json.decode(contentsString);
          expect(
            contents['can-commit']['success']['hash'],
            hash,
          );
        });
      });
    });

    group('readSuccess(directory, key, ggLog)', () {
      group('should return', () {
        group('false', () {
          test('if no .gg.json exists', () async {
            expect(await File('${d.path}/.gg.json').exists(), isFalse);
            final result = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result, isFalse);
          });

          test('if .gg.json is empty', () async {
            File('${d.path}/.gg.json').writeAsStringSync('{}');

            final result = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result, isFalse);
          });

          test('if last success hash is not current hash', () async {
            // Set the state
            await ggState.writeSuccess(
              directory: d,
              key: 'can-commit',
            );

            // Change the file
            await addAndCommitSampleFile(d);

            final result = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result, isFalse);
          });
        });

        group('true', () {
          test('if last success hash is current hash', () async {
            // Commit something
            await addAndCommitSampleFile(d, fileName: 'file0.txt');

            // Write success after everything is committed
            await ggState.writeSuccess(
              directory: d,
              key: 'can-commit',
            );

            // Read succes -> It should be true
            final result = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result, isTrue);

            // Make a modification
            await File('${d.path}/file0.txt').writeAsString('modified');

            // Read success -> It should be false
            final result2 = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result2, isFalse);

            // Write success again
            await ggState.writeSuccess(
              directory: d,
              key: 'can-commit',
            );

            // Read success -> It should be true
            final result3 = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result3, isTrue);

            // Commit the last changes.
            // This should not change the success state.
            await commitFile(d, 'file0.txt');

            // Read success -> It should be true
            final result4 = await ggState.readSuccess(
              directory: d,
              ggLog: messages.add,
              key: 'can-commit',
            );
            expect(result4, isTrue);
          });
        });
      });
    });
  });
}
