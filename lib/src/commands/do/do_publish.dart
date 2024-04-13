// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart' as changelog;
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:gg_version/gg_version.dart';
import 'package:path/path.dart';

/// Publishes the current directory.
class DoPublish extends DirCommand<void> {
  /// Constructor
  DoPublish({
    required super.ggLog,
    super.name = 'publish',
    super.description = 'Publishes the current directory.',
    CanPublish? canPublish,
    Publish? publish,
    GgState? state,
    AddVersionTag? addVersionTag,
    Commit? commit,
    DoPush? doPush,
    PrepareNextVersion? prepareNextVersion,
    FromPubspec? fromPubspec,
    IsPublished? isPublished,
    changelog.Release? release,
    PublishTo? publishTo,
  })  : _canPublish = canPublish ?? CanPublish(ggLog: ggLog),
        _publishToPubDev = publish ?? Publish(ggLog: ggLog),
        _state = state ?? GgState(ggLog: ggLog),
        _addVersionTag = addVersionTag ?? AddVersionTag(ggLog: ggLog),
        _commit = commit ?? Commit(ggLog: ggLog),
        _doPush = doPush ?? DoPush(ggLog: ggLog),
        _prepareNextVersion =
            prepareNextVersion ?? PrepareNextVersion(ggLog: ggLog),
        _fromPubspec = fromPubspec ?? FromPubspec(ggLog: ggLog),
        _releaseChangelog = release ?? changelog.Release(ggLog: ggLog),
        _isPublished = isPublished ?? IsPublished(ggLog: ggLog),
        _publishTo = publishTo ?? PublishTo(ggLog: ggLog) {
    _addArgs();
  }

  // ...........................................................................
  /// The key used to save the state of the command
  final String stateKey = 'doPublish';

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    bool? askBeforePublishing,
  }) =>
      get(
        directory: directory,
        ggLog: ggLog,
        askBeforePublishing: askBeforePublishing,
      );

  // ...........................................................................
  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    bool? askBeforePublishing,
  }) async {
    // Does directory exist?
    await check(directory: directory);
    void noLog(_) {} // coverage:ignore-line

    // Did already publish?
    final isDone = await _state.readSuccess(
      directory: directory,
      key: stateKey,
      ggLog: ggLog,
    );

    if (isDone) {
      ggLog(yellow('Current state is already published.'));
      return;
    }

    // Should ask before publishing?
    askBeforePublishing = await _shouldAskBeforePublishing(
      directory,
      ggLog,
      askBeforePublishing,
    );

    // Can publish?
    await _canPublish.exec(
      directory: directory,
      ggLog: ggLog,
    );

    // Publish change log using cider
    await _prepareChangelog(
      directory: directory,
      ggLog: noLog,
    );

    // Publish on pub.dev
    final publishToPubDev = await _shouldPublishToPubDev(directory, ggLog);

    if (publishToPubDev) {
      await _publishToPubDev.exec(
        directory: directory,
        ggLog: ggLog,
        askBeforePublishing: askBeforePublishing,
      );
    }

    // Save state
    await _state.writeSuccess(
      directory: directory,
      key: stateKey,
    );

    // Push commits to remote
    await _doPush.exec(
      directory: directory,
      ggLog: (_) {}, // coverage:ignore-line
      force: false,
    );

    // Add git version tag
    await _addVersionTag.exec(
      directory: directory,
      ggLog: (msg) => ggLog('✅ $msg'),
    );

    // Push tags to remote
    await _doPush.gitPush(
      directory: directory,
      force: false,
      pushTags: true,
    );

    // Prepare next version
    await _addNextVersion(directory, ggLog);
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final Publish _publishToPubDev;
  final CanPublish _canPublish;
  final GgState _state;
  final AddVersionTag _addVersionTag;
  final DoPush _doPush;
  final Commit _commit;
  final PrepareNextVersion _prepareNextVersion;
  final FromPubspec _fromPubspec;
  final changelog.Release _releaseChangelog;
  final IsPublished _isPublished;
  final PublishTo _publishTo;

  // ...........................................................................
  Future<void> _prepareChangelog({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Remember current hash
    final hashBefore = await _state.currentHash(
      directory: directory,
      ggLog: ggLog,
    );

    // Release the changelog
    await _releaseChangelog.exec(
      directory: directory,
      ggLog: ggLog,
    );

    // Update state
    await _state.updateHash(
      hash: hashBefore,
      directory: directory,
    );

    // Commit changes to change log
    await _commit.commit(
      ggLog: ggLog,
      directory: directory,
      doStage: true,
      message: 'Prepare changelog for release',
      ammendWhenNotPushed: true,
    );
  }

  // ...........................................................................
  Future<void> _addNextVersion(Directory directory, GgLog ggLog) async {
    // Define increment
    const increment = VersionIncrement.patch;

    // Remember current hash
    final hashBefore = await _state.currentHash(
      directory: directory,
      ggLog: ggLog,
    );

    // Get version in pubspec.yaml
    final publishedVersion = await _fromPubspec.fromDirectory(
      directory: directory,
    );

    // Prepare the next version
    await _prepareNextVersion.exec(
      directory: directory,
      ggLog: ggLog,
      increment: increment,
      publishedVersion: publishedVersion,
    );

    // Update state
    await _state.updateHash(
      hash: hashBefore,
      directory: directory,
    );

    // Get new version
    final newVersion = await _fromPubspec.fromDirectory(
      directory: directory,
    );

    // Commit changes to change log
    await _commit.commit(
      ggLog: ggLog,
      directory: directory,
      doStage: true,
      message: 'Prepare development of version $newVersion',
      ammendWhenNotPushed: false,
    );

    // Push commits to remote
    await _doPush.gitPush(
      directory: directory,
      force: false,
    );
  }

  // ...........................................................................
  Future<bool> _shouldAskBeforePublishing(
    Directory directory,
    GgLog ggLog,
    bool? askBeforePublishing,
  ) async {
    askBeforePublishing ??= _askBeforePublishingFromParam;

    // Where should the package be published?
    final target = await _publishTo.fromDirectory(directory);
    final publishToNone = target == 'none';
    if (publishToNone) {
      return false;
    }

    // Check package was published before
    final wasPublishedBefore = await _isPublished.get(
      directory: directory,
      ggLog: ggLog,
    );

    // When --ask-for-confirmation is true, always ask
    if (askBeforePublishing) {
      return true;
    }

    // When --ask-for-confirmation is false,
    // don't ask, when package is already published
    if (wasPublishedBefore) {
      return false;
    }

    /// If the package was never published before,
    /// and askBeforePublishing is false,
    /// throw an exception.
    /// Before publishing the package the first time,
    /// always ask.
    throw Exception(
      'The package was never published to pub.dev before. '
      'Please call »gg do push« with »--ask-before-publishing« '
      'when publishing the first time.',
    );
  }

  // ...........................................................................
  Future<bool> _shouldPublishToPubDev(
    Directory directory,
    GgLog ggLog,
  ) async {
    final pubspecFile = File(join(directory.path, 'pubspec.yaml'));
    final pubspec = await pubspecFile.readAsString();
    return !pubspec.contains(RegExp(r'publish_to:'));
  }

  // ...........................................................................
  bool get _askBeforePublishingFromParam =>
      argResults?['ask-before-publishing'] as bool? ?? true;

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'ask-before-publishing',
      abbr: 'a',
      help: 'Ask for confirmation before publishing to pub.dev.',
      defaultsTo: true,
      negatable: true,
    );
  }
}

/// Mock for [DoPublish].
class MockDoPublish extends MockDirCommand<void> implements DoPublish {}
