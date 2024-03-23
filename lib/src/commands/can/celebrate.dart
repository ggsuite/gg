// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

/// Checks if the changes can be pushed.
class Celebrate extends CommandCluster {
  /// Constructor
  Celebrate({
    required super.ggLog,
    Checks? checkCommands,
    super.name = 'celebrate',
    super.description =
        'Checks if everything is done and we can start the party.',
    super.shortDescription = 'Can celebrate?',
  }) : super(commands: _checks(checkCommands, ggLog));

  // ...........................................................................
  static List<DirCommand<void>> _checks(
    Checks? checks,
    GgLog ggLog,
  ) {
    checks ??= Checks(ggLog: ggLog);
    return [
      checks.isPublished,
    ];
  }
}

// .............................................................................
/// A mocktail mock
class MockCelebrate extends mocktail.Mock implements Celebrate {}
