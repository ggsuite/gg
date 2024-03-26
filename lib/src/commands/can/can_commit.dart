// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

/// Checks if the changes can be committed.
class CanCommit extends CommandCluster {
  /// Constructor
  CanCommit({
    required super.ggLog,
    Checks? checks,
    super.name = 'commit',
    super.description = 'Checks if code is ready to commit.',
    super.shortDescription = 'Can commit?',
  }) : super(commands: _checks(checks, ggLog));

  // ...........................................................................
  static List<DirCommand<void>> _checks(
    Checks? checks,
    GgLog ggLog,
  ) {
    checks ??= Checks(ggLog: ggLog);
    return [
      checks.analyze,
      checks.format,
      checks.tests,
    ];
  }
}

// .............................................................................
/// A mocktail mock
class MockCommit extends mocktail.Mock implements CanCommit {}
