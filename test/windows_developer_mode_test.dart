// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/windows_developer_mode.dart';
import 'package:gg_is_github/gg_is_github.dart';
import 'package:test/test.dart';

import 'fake_windows_developer_mode.dart';

void main() {
  final messages = <String>[];

  setUp(messages.clear);

  Future<bool> check([List<String> args = const ['can', 'commit']]) =>
      checkWindowsDeveloperMode(args: args, ggLog: messages.add);

  group('checkWindowsDeveloperMode()', () {
    test('queries the developer mode value with reg', () async {
      final reg = FakeReg.value('0x1');
      fakeWindows(reg);
      await check();

      expect(reg.calls, [
        [
          'reg',
          'query',
          r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock',
          '/v',
          'AllowDevelopmentWithoutDevLicense',
        ],
      ]);
    });

    test('passes silently for 0x1', () async {
      fakeWindows(FakeReg.value('0x1'));
      expect(await check(), isTrue);
      expect(messages, isEmpty);
    });

    group('fails with a hint', () {
      void expectHint() {
        final output = messages.join('\n');
        expect(output, contains('gg needs the Windows developer mode'));
        expect(output, contains('Settings → System → For developers'));
        expect(output, contains('start ms-settings:developers'));
      }

      test('for 0x0', () async {
        fakeWindows(FakeReg.value('0x0'));
        expect(await check(), isFalse);
        expectHint();
      });

      test('when the value does not exist', () async {
        fakeWindows(FakeReg(exitCode: 1));
        expect(await check(), isFalse);
        expectHint();
      });
    });

    group('warns but passes', () {
      void expectWarning() => expect(
        messages.join('\n'),
        contains('Could not check whether the Windows developer mode'),
      );

      test('when reg cannot be started', () async {
        fakeWindows(FakeReg(error: const ProcessException('reg', [])));
        expect(await check(), isTrue);
        expectWarning();
      });

      test('for output it does not understand', () async {
        fakeWindows(FakeReg(stdout: 'something else'));
        expect(await check(), isTrue);
        expectWarning();
      });
    });

    group('skips the check', () {
      late FakeReg reg;

      setUp(() => reg = FakeReg(exitCode: 1));

      Future<void> expectSkipped([
        List<String> args = const ['can', 'commit'],
      ]) async {
        expect(await check(args), isTrue);
        expect(reg.calls, isEmpty);
        expect(messages, isEmpty);
      }

      test('off Windows', () async {
        fakeWindows(reg, platform: const FakePlatform('linux'));
        await expectSkipped();
      });

      test('on GitHub Actions', () async {
        fakeWindows(reg);
        testIsGitHub = true;
        await expectSkipped();
      });

      test('for usage-only calls', () async {
        fakeWindows(reg);
        await expectSkipped([]);
        await expectSkipped(['help', 'can']);
        await expectSkipped(['do', 'commit', '-h']);
      });
    });
  });
}
