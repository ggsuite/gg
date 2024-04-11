// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/tools/did_command.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_publish/gg_publish.dart';

/// Are the dependencies of the package upgraded?
class DidUpgrade extends DidCommand {
  /// Constructor
  DidUpgrade({
    required super.ggLog,
    super.name = 'upgrade',
    super.description = 'Are the dependencies of the package upgraded?',
    super.shortDescription = 'Everything is upgraded',
    super.suggestion = 'Not upgraded yet. Please run »gg do upgrade.«',
    super.stateKey = 'doCommit',
    IsUpgraded? isUpgraded,
    DidPublish? didPublish,
  })  : _isUpgraded = isUpgraded ?? IsUpgraded(ggLog: ggLog),
        _didPublish = didPublish ?? DidPublish(ggLog: ggLog);

  // ...........................................................................
  /// Returns previously set value
  @override
  Future<bool> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    /// Is everything upgraded?
    final isUpgraded = await _isUpgraded.get(
      directory: directory,
      ggLog: ggLog,
    );

    if (!isUpgraded) {
      return false;
    }

    /// Is everything published?
    final didPublish = await _didPublish.get(
      directory: directory,
      ggLog: ggLog,
    );

    return didPublish;
  }

  // ######################
  // Private
  // ######################

  final DidPublish _didPublish;
  final IsUpgraded _isUpgraded;
}

/// Mock for [DidUpgrade]
class MockDidUpgrade extends MockDidCommand implements DidUpgrade {}
