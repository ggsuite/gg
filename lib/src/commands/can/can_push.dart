// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';

/// Checks if the changes can be pushed.
class CanPush extends CommandCluster {
  /// Constructor
  CanPush({
    required super.ggLog,
    Checks? checkCommands,
    super.name = 'push',
    super.shortDescription = 'Can push?',
    super.description = 'Checks if code is ready to push.',
    super.stateKey = 'canPush',
  }) : super(commands: _checks(checkCommands, ggLog));

  // ...........................................................................
  static List<DirCommand<void>> _checks(
    Checks? checks,
    GgLog ggLog,
  ) {
    checks ??= Checks(ggLog: ggLog);
    return [
      checks.isUpgraded,
      checks.isCommitted,
    ];
  }
}

// .............................................................................
/// A mocktail mock
class MockPush extends Mock implements CanPush {}
