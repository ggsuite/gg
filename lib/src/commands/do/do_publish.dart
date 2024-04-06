// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_publish.dart';
import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart' as changelog;
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart';

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
    changelog.Release? release,
  })  : _canPublish = canPublish ?? CanPublish(ggLog: ggLog),
        _publish = publish ?? Publish(ggLog: ggLog),
        _state = state ?? GgState(ggLog: ggLog),
        _addVersionTag = addVersionTag ?? AddVersionTag(ggLog: ggLog),
        _commit = commit ?? Commit(ggLog: ggLog),
        _doPush = doPush ?? DoPush(ggLog: ggLog),
        _prepareNextVersion =
            prepareNextVersion ?? PrepareNextVersion(ggLog: ggLog),
        _fromPubspec = fromPubspec ?? FromPubspec(ggLog: ggLog),
        _releaseChangelog = release ?? changelog.Release(ggLog: ggLog);

  // ...........................................................................
  /// The key used to save the state of the command
  final String stateKey = 'doPublish';

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Does directory exist?
    await check(directory: directory);
    void noLog(_) {}

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

    // Publish
    await _publish.exec(
      directory: directory,
      ggLog: ggLog,
    );

    // Save state
    await _state.writeSuccess(
      directory: directory,
      key: stateKey,
    );

    // Add git version tag
    await _addVersionTag.exec(
      directory: directory,
      ggLog: ggLog,
    );

    // Push commits to remote
    await _doPush.exec(
      directory: directory,
      ggLog: (_) {}, // coverage:ignore-line
      force: false,
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
  final Publish _publish;
  final CanPublish _canPublish;
  final GgState _state;
  final AddVersionTag _addVersionTag;
  final DoPush _doPush;
  final Commit _commit;
  final PrepareNextVersion _prepareNextVersion;
  final FromPubspec _fromPubspec;
  final changelog.Release _releaseChangelog;

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

    // Prepare the next version
    await _prepareNextVersion.exec(
      directory: directory,
      ggLog: ggLog,
      increment: increment,
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
}

/// Mock for [DoPublish].
class MockDoPublish extends Mock implements DoPublish {}
