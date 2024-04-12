// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late CommandRunner<void> runner;
  late DoUpgrade doUpgrade;

  // ...........................................................................
  late GgState? state;
  late MockDidUpgrade didUpgrade;
  late MockCanUpgrade canUpgrade;
  late MockGgProcessWrapper processWrapper;
  late MockCanCommit canCommit;
  late MockDoCommit doCommit;
  late MockDoPublish doPublish;

  // ...........................................................................
  void initMocks() {
    registerFallbackValue(d);
    state = GgState(ggLog: ggLog);
    didUpgrade = MockDidUpgrade();
    canUpgrade = MockCanUpgrade();
    processWrapper = MockGgProcessWrapper();
    canCommit = MockCanCommit();
    doCommit = MockDoCommit();
    doPublish = MockDoPublish();
  }

  // ...........................................................................
  void initDoUpgrade() {
    doUpgrade = DoUpgrade(
      ggLog: ggLog,
      state: state,
      didUpgrade: didUpgrade,
      canUpgrade: canUpgrade,
      processWrapper: processWrapper,
      canCommit: canCommit,
      doCommit: doCommit,
      doPublish: doPublish,
    );

    runner.addCommand(doUpgrade);
  }

  // ...........................................................................
  void mockDartPubUpgrade({
    bool majorVersions = false,
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    bool upgradingCausesChange = true,
  }) {
    when(
      () => processWrapper.run(
        'dart',
        ['pub', 'upgrade', if (majorVersions) '--major-versions'],
        workingDirectory: d.path,
      ),
    ).thenAnswer(
      (_) async {
        if (upgradingCausesChange) {
          await updateSampleFileWithoutCommitting(d);
        }

        return ProcessResult(
          0,
          exitCode,
          stdout,
          stderr,
        );
      },
    );
  }

  // ...........................................................................
  void mockCanCommit({bool success = true}) {
    when(
      () => canCommit.exec(
        directory: any(
          named: 'directory',
          that: predicate<Directory>((dir) => dir.path == d.path),
        ),
        ggLog: ggLog,
        force: true,
      ),
    ).thenAnswer(
      (_) async {
        if (success) {
          ggLog('✅ CanCommit');
          return Future.value();
        } else {
          throw Exception('CanCommit failed.');
        }
      },
    );
  }

  // ...........................................................................
  void mockDoCommit() {
    when(
      () => doCommit.exec(
        directory: any(
          named: 'directory',
          that: predicate<Directory>((dir) => dir.path == d.path),
        ),
        ggLog: ggLog,
        message: 'Upgraded package dependencies',
        logType: LogType.changed,
      ),
    ).thenAnswer(
      (_) async {
        ggLog('✅ DoCommit');
        return Future.value();
      },
    );
  }

  // ...........................................................................
  void mockDoPublish() {
    when(
      () => doPublish.exec(
        directory: any(
          named: 'directory',
          that: predicate<Directory>((dir) => dir.path == d.path),
        ),
        ggLog: ggLog,
        askBeforePublishing: false,
      ),
    ).thenAnswer(
      (_) async {
        ggLog('✅ DoPublish');
        return Future.value();
      },
    );
  }

  // ...........................................................................
  void initDefaultMocks() {
    didUpgrade.mockGet(result: false, directory: d, ggLog: null);
    canUpgrade.mockExec(result: null, directory: d, ggLog: ggLog);
    mockCanCommit();
    mockDoCommit();
    mockDartPubUpgrade();
    mockDoPublish();
  }

  // ...........................................................................
  setUp(() async {
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitSampleFile(d);

    messages.clear();
    runner = CommandRunner<void>('gg', 'gg');
    initMocks();
    initDoUpgrade();
    initDefaultMocks();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  // ...........................................................................
  group('DoUpgrade', () {
    group('- main case', () {
      group(
          '- should run »dart pub upggrade», '
          'check if everything still runs (canCommit) '
          'and finally commit and publish changes', () {
        void check() {
          expect(messages[0], contains('✅ CanUpgrade'));
          expect(messages[1], contains('⌛️ Run »dart pub upgrade«'));
          expect(messages[2], contains('✅ Run »dart pub upgrade«'));
          expect(messages[3], contains('✅ CanCommit'));
          expect(messages[4], contains('✅ DoCommit'));
          expect(messages[5], contains('✅ DoPublish'));
        }

        test('- programmatically', () async {
          await doUpgrade.exec(directory: d, ggLog: ggLog);
          check();
        });

        test('- via CLI', () async {
          await runner.run(['upgrade', '-i', d.path]);
          check();
        });
      });
    });

    group('- special cases', () {
      group('- should fail', () {
        group('- when preconditions for can upgrade are not met', () {
          setUp(() {
            // Let canUpgrade fail
            canUpgrade.mockExec(
              result: null,
              directory: d,
              doThrow: true, // <- Throws
              message: 'CanUpgrade failed',
            );
          });

          Future<void> perform(Future<void> testCode) async {
            late String exception;
            try {
              await testCode;
            } catch (e) {
              exception = e.toString();
            }
            expect(exception, contains('CanUpgrade failed'));
          }

          test('- programmatically', () async {
            await perform(
              doUpgrade.exec(directory: d, ggLog: ggLog),
            );
          });

          test('- via CLI', () async {
            await perform(
              runner.run(['upgrade', d.path, '-i', d.path]),
            );
          });
        });

        test('- when »dart pub upgrade« exists with an error', () async {
          mockDartPubUpgrade(
            exitCode: 1,
            stderr: 'Something went wrong',
          );

          late String exception;
          try {
            await doUpgrade.exec(directory: d, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }
          expect(
            exception,
            contains(
              '»dart pub upgrade« failed: Something went wrong',
            ),
          );
        });
      });

      group('- should do nothing', () {
        group('- when everything is already upgraded', () {
          setUp(() {
            // Let's say didUpgrade returns true
            didUpgrade.mockGet(result: true, directory: d);
          });

          void check() {
            expect(
              messages.last,
              yellow('Everything is already up to date.'),
            );
          }

          test('- programmatically', () async {
            await doUpgrade.exec(directory: d, ggLog: ggLog);
            check();
          });

          test('- via CLI', () async {
            await runner.run(['upgrade', d.path, '-i', d.path]);
            check();
          });
        });
      });

      group('- should not commit and publish ', () {
        test(
          'when nothing was changed by »dart pub upgrade«',
          () async {
            mockDartPubUpgrade(upgradingCausesChange: false);
            await doUpgrade.exec(directory: d, ggLog: ggLog);
            final allMessages = messages.join('\n');
            expect(allMessages, isNot(contains('✅ DoCommit')));
            expect(allMessages, isNot(contains('✅ DoPublish')));
          },
        );
      });

      test('- should require fixing errors happening through updating',
          () async {
        mockCanCommit(success: false);

        late String exception;
        try {
          await doUpgrade.exec(directory: d, ggLog: ggLog);
        } catch (e) {
          exception = e.toString();
        }

        final message = red(
          'After the update tests are not running anymore. '
          'Please run ${blue('»gg can commit«')} and try again.',
        );

        expect(exception, contains(message));
      });

      group('- should allow to upgrade major versions', () {
        setUp(() {
          mockDartPubUpgrade(majorVersions: true);
        });

        tearDown(() {
          expect(
            messages[1],
            contains('⌛️ Run »dart pub upgrade --major-versions«'),
          );

          expect(
            messages[2],
            contains('✅ Run »dart pub upgrade --major-versions«'),
          );
        });

        test('- programmatically', () async {
          await doUpgrade.exec(
            directory: d,
            ggLog: ggLog,
            majorVersions: true,
          );
        });

        test('- via CLI', () async {
          await runner.run(['upgrade', '-i', d.path, '--major-versions']);
        });
      });

      test('- should init DoUpgrade with default params', () {
        expect(() => DoUpgrade(ggLog: ggLog), returnsNormally);
      });
    });
  });
}
