// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/gg_check.dart';
import 'package:test/test.dart';

void main() {
  // ...........................................................................
  final messages = <String>[];
  final cr = carriageReturn;

  // ...........................................................................
  setUp(() {
    messages.clear();
  });

  tearDown(() {
    testIsGitHub = null;
  });

  // ...........................................................................
  group('LogState(state, message, log)', () {
    group('for GitHub actions', () {
      group('should not print carriage returns', () {
        test('for success messages', () {
          testIsGitHub = true;
          logState(
            state: LogState.success,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['✅ message']);
        });

        test('for error messages', () {
          testIsGitHub = true;
          logState(
            state: LogState.error,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['❌ message']);
        });

        test('for running messages', () {
          testIsGitHub = true;
          logState(
            state: LogState.running,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['⌛️ message']);
        });
      });
    });

    group('for local actions', () {
      group('should print carriage returns', () {
        test('for success messages', () {
          testIsGitHub = false;
          logState(
            state: LogState.success,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['$cr✅ message']);
        });

        test('for error messages', () {
          testIsGitHub = false;
          logState(
            state: LogState.error,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['$cr❌ message']);
        });

        test('for running messages', () {
          testIsGitHub = false;
          logState(
            state: LogState.running,
            message: 'message',
            ggLog: messages.add,
          );
          expect(messages, ['⌛️ message']);
        });
      });
    });

    group('for unspecified environment', () {
      test('should read isGitHub', () {
        testIsGitHub = null;
        logState(
          state: LogState.success,
          message: 'message',
          ggLog: messages.add,
        );
        final cr = isGitHub ? '' : carriageReturn;
        expect(messages, ['$cr✅ message']);
      });
    });
  });
}
