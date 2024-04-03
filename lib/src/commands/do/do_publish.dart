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
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:gg_version/gg_version.dart';

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
    DoPush? doPush,
  })  : _canPublish = canPublish ?? CanPublish(ggLog: ggLog),
        _publish = publish ?? Publish(ggLog: ggLog),
        _state = state ?? GgState(ggLog: ggLog),
        _addVersionTag = addVersionTag ?? AddVersionTag(ggLog: ggLog),
        _doPUsh = doPush ?? DoPush(ggLog: ggLog);

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

    // Push to remote
    await _doPUsh.exec(
      directory: directory,
      ggLog: ggLog,
    );
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final Publish _publish;
  final CanPublish _canPublish;
  final GgState _state;
  final AddVersionTag _addVersionTag;
  final DoPush _doPUsh;
}
