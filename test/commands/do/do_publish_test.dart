// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_direct_json/gg_direct_json.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late Directory dRemote;
  late Directory Function() dMock;
  late DoPublish doPublish;
  late CanPublish canPublish;
  late PublishedVersion publishedVersion;
  late IsVersionPrepared isVersionPrepared;

  late int successHash;
  late int needsChangeHash;
  late Version publishedVersionValue;

  // ...........................................................................
  // Mocks
  late Publish publish;

  void mockPublishIsSuccessful({
    required bool success,
    required bool askBeforePublishing,
  }) =>
      when(
        () => publish.exec(
          directory: dMock(),
          ggLog: ggLog,
          askBeforePublishing: askBeforePublishing,
        ),
      ).thenAnswer((_) async {
        if (!success) {
          throw Exception('Publishing failed.');
        } else {
          publishedVersionValue = Version.parse('1.2.4');
          ggLog('Publishing was successful.');
        }
      });

  void mockPublishedVersion() =>
      when(
        () => publishedVersion.get(
          directory: dMock(),
          ggLog: any(named: 'ggLog'),
        ),
      ).thenAnswer((_) async {
        return publishedVersionValue;
      });

  // ...........................................................................
  Future<void> makeLastStateSuccessful() async {
    successHash = await LastChangesHash(
      ggLog: ggLog,
    ).get(directory: d, ggLog: ggLog, ignoreFiles: GgState.ignoreFiles);

    await File(join(d.path, '.gg.json')).writeAsString(
      '{"canCommit":{"success":{"hash":$successHash}},'
      '"doCommit":{"success":{"hash":$successHash}},'
      '"canPush":{"success":{"hash":$successHash}},'
      '"doPush":{"success":{"hash":$successHash}},'
      '"canPublish":{"success":{"hash":$successHash}},'
      '"doPublish":{"success":{"hash":$successHash}}}',
    );
  }

  // ...........................................................................
  setUp(() async {
    // Create repositories
    d = await Directory.systemTemp.createTemp('local');
    await initLocalGit(d);
    dRemote = await Directory.systemTemp.createTemp('remote');
    await initRemoteGit(dRemote);
    await addRemoteToLocal(local: d, remote: dRemote);
    publishedVersionValue = Version.parse('1.2.3');

    // Clear messagesa
    messages.clear();

    // Setup a pubspec.yaml and a CHANGELOG.md with right versions
    await File(join(d.path, 'pubspec.yaml')).writeAsString(
      'name: gg\n\nversion: 1.2.4\n'
      'repository: https://github.com/inlavigo/gg.git',
    );

    // Prepare ChangeLog
    await File(join(d.path, 'CHANGELOG.md')).writeAsString(
      '# Changelog\n\n'
      '## Unreleased\n'
      '-Message 1\n'
      '-Message 2\n'
      '## 1.2.3 - 2024-04-05\n\n- First version',
    );

    // Create a .gg.json that has all preconditions for publishing
    needsChangeHash = 12345;

    // Mock publishing
    dMock = () => any(
      named: 'directory',
      that: predicate<Directory>((x) => x.path == d.path),
    );
    registerFallbackValue(d);
    publish = MockPublish();

    publishedVersion = MockPublishedVersion();

    isVersionPrepared = IsVersionPrepared(
      ggLog: ggLog,
      publishedVersion: publishedVersion,
    );

    canPublish = CanPublish(ggLog: ggLog, isVersionPrepared: isVersionPrepared);
    mockPublishedVersion();

    // Instantiate with mocks
    doPublish = DoPublish(
      ggLog: ggLog,
      publish: publish,
      prepareNextVersion: PrepareNextVersion(
        ggLog: ggLog,
        publishedVersion: publishedVersion,
      ),
      canPublish: canPublish,
      isPublished: IsPublished(
        ggLog: ggLog,
        publishedVersion: publishedVersion,
      ),
    );

    await makeLastStateSuccessful();
  });

  tearDown(() async {
    await d.delete(recursive: true);
    await dRemote.delete(recursive: true);
  });

  group('DoPublish', () {
    group('exec(directory)', () {
      group('should succeed', () {
        group('and not publish', () {
          test('when publishing was already successful', () async {
            await DirectJson.writeFile(
              file: File(join(d.path, '.gg.json')),
              path: 'doPublish/success/hash',
              value: successHash,
            );

            await doPublish.exec(directory: d, ggLog: ggLog);
            expect(messages[0], yellow('Current state is already published.'));
          });
        });
        group('and publish', () {
          group('to pub.dev', () {
            group('when no »publish_to: none« is found in pubspec.yaml', () {
              group('when the package', () {
                group('has been published before', () {
                  group('and ask for confirmation', () {
                    for (final ask in [true, null]) {
                      test('when askBeforePublishing is $ask', () async {
                        // Expect asking for confirmation
                        mockPublishIsSuccessful(
                          success: true,
                          askBeforePublishing: true,
                        );

                        // Mock needing publish
                        await DirectJson.writeFile(
                          file: File(join(d.path, '.gg.json')),
                          path: 'doPublish/success/hash',
                          value: needsChangeHash,
                        );

                        // Publish
                        await doPublish.exec(
                          directory: d,
                          ggLog: ggLog,
                          askBeforePublishing: ask,
                        );

                        // Were the steps performed?
                        var i = 0;
                        expect(messages[i++], contains('Can publish?'));
                        expect(
                          messages[i++],
                          contains('✅ Everything is fine.'),
                        );
                        expect(
                          messages[i++],
                          contains('Publishing was successful.'),
                        );
                        expect(messages[i++], contains('✅ Tag 1.2.4 added.'));
                        expect(messages[i++], contains('⌛️ Increase version'));
                        expect(messages[i++], contains('✅ Increase version'));

                        // Was a new version created?
                        final pubspec = await File(
                          join(d.path, 'pubspec.yaml'),
                        ).readAsString();
                        final changeLog = await File(
                          join(d.path, 'CHANGELOG.md'),
                        ).readAsString();
                        expect(pubspec, contains('version: 1.2.5'));
                        expect(changeLog, contains('## [1.2.4] -'));

                        // Was the new version checked in?
                        final headMessage = await HeadMessage(
                          ggLog: ggLog,
                        ).get(directory: d, ggLog: ggLog);
                        expect(
                          headMessage,
                          'Prepare development of version 1.2.5',
                        );

                        // Was .gg.json updated in a way that didCommit,
                        // didPush and didPublish return true?
                        expect(
                          await DidCommit(
                            ggLog: ggLog,
                          ).get(directory: d, ggLog: ggLog),
                          isTrue,
                        );

                        expect(
                          await DidPush(
                            ggLog: ggLog,
                          ).get(directory: d, ggLog: ggLog),
                          isTrue,
                        );

                        expect(
                          await DidPublish(
                            ggLog: ggLog,
                          ).get(directory: d, ggLog: ggLog),
                          isTrue,
                        );
                      });
                    }
                  });

                  group('has not been published before', () {
                    test('and askForConfirmation is true', () async {
                      /// Mock that the package was never published before
                      publishedVersionValue = Version(0, 0, 0);
                      mockPublishedVersion();

                      // Expect asking for confirmation
                      mockPublishIsSuccessful(
                        success: true,
                        askBeforePublishing: true,
                      );

                      // Mock needing publish
                      await DirectJson.writeFile(
                        file: File(join(d.path, '.gg.json')),
                        path: 'doPublish/success/hash',
                        value: needsChangeHash,
                      );

                      // Publish
                      await doPublish.exec(
                        directory: d,
                        ggLog: ggLog,
                        askBeforePublishing: true,
                      );

                      // Check
                      expect(
                        await DidPublish(
                          ggLog: ggLog,
                        ).get(directory: d, ggLog: ggLog),
                        isTrue,
                      );
                    });
                  });
                });
              });

              group('without asking for confirmation', () {
                test('when askBeforePublishing is false', () async {
                  // Expect not asking for confirmation
                  mockPublishIsSuccessful(
                    success: true,
                    askBeforePublishing: false,
                  );

                  // Mock needing publish
                  await DirectJson.writeFile(
                    file: File(join(d.path, '.gg.json')),
                    path: 'doPublish/success/hash',
                    value: needsChangeHash,
                  );

                  // Publish
                  await doPublish.exec(
                    directory: d,
                    ggLog: ggLog,
                    askBeforePublishing: false,
                  );

                  // Check result
                  expect(
                    await DidPublish(
                      ggLog: ggLog,
                    ).get(directory: d, ggLog: ggLog),
                    isTrue,
                  );
                });
              });
            });
          });

          group('not to pub.dev', () {
            test('when »publish_to: none« is found in pubspec.yaml', () async {
              doPublish = DoPublish(ggLog: ggLog, publish: publish);

              // Prepare pubspec.yaml
              final pubspecFile = File(join(d.path, 'pubspec.yaml'));
              const nextVersion = '1.0.1';
              const currentVersion = '1.0.0';
              await addAndCommitVersions(
                d,
                pubspec: nextVersion,
                changeLog: 'Unreleased',
                gitHead: currentVersion,
                appendToPubspec: '\npublish_to: none', // No publish to pub.dev
              );
              var pubspec = await pubspecFile.readAsString();
              expect(pubspec, contains('version: 1.0.1'));

              await makeLastStateSuccessful();

              // Mock needing publish
              await DirectJson.writeFile(
                file: File(join(d.path, '.gg.json')),
                path: 'doPublish/success/hash',
                value: needsChangeHash,
              );

              // Publish
              await doPublish.exec(directory: d, ggLog: ggLog);

              // Were the steps performed?
              var i = 0;
              expect(messages[i++], contains('Can publish?'));
              expect(messages[i++], contains('✅ Everything is fine.'));
              expect(messages[i++], contains('Tag 1.0.1 added.'));
              expect(messages[i++], contains('⌛️ Increase version'));
              expect(messages[i++], contains('✅ Increase version'));

              // Was a new version created?
              pubspec = await pubspecFile.readAsString();
              final changeLog = await File(
                join(d.path, 'CHANGELOG.md'),
              ).readAsString();
              expect(pubspec, contains('version: 1.0.2'));
              expect(changeLog, contains('## [1.0.1] -'));

              // Was the new version checked in?
              final headMessage = await HeadMessage(
                ggLog: ggLog,
              ).get(directory: d, ggLog: ggLog);
              expect(headMessage, 'Prepare development of version 1.0.2');

              // Was .gg.json updated in a way that didCommit,
              // didPush and didPublish return true?
              expect(
                await DidCommit(ggLog: ggLog).get(directory: d, ggLog: ggLog),
                isTrue,
              );

              expect(
                await DidPush(ggLog: ggLog).get(directory: d, ggLog: ggLog),
                isTrue,
              );

              expect(
                await DidPublish(ggLog: ggLog).get(directory: d, ggLog: ggLog),
                isTrue,
              );
            });
          });
        });
      });

      group('and throw', () {
        group('when the package is published the first time', () {
          group('has not been published before', () {
            test('and askForConfirmation is false', () async {
              /// Mock that the package was never published before
              publishedVersionValue = Version(0, 0, 0);
              mockPublishedVersion();

              // Mock needing publish
              await DirectJson.writeFile(
                file: File(join(d.path, '.gg.json')),
                path: 'doPublish/success/hash',
                value: needsChangeHash,
              );

              // Publish with askBeforePublishing = false
              late String exception;

              try {
                await doPublish.exec(
                  directory: d,
                  ggLog: ggLog,
                  askBeforePublishing: false,
                );
              } catch (e) {
                exception = e.toString();
              }

              // Should throw
              expect(
                exception,
                contains(
                  'Please call »gg do push« with »--ask-before-publishing«',
                ),
              );

              // Check
              expect(
                await DidPublish(ggLog: ggLog).get(directory: d, ggLog: ggLog),
                isFalse,
              );
            });
          });
        });
      });
    });

    test('should have a code coverage of 100%', () {
      expect(DoPublish(ggLog: ggLog), isNotNull);
    });
  });
}
