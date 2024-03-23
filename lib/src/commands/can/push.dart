// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import '../check.dart';

/// Checks if the changes can be pushed.
class Push extends DirCommand<void> {
  /// Constructor
  Push({
    required super.ggLog,
    CheckCommands? checkCommands,
  })  : _checkCommands = checkCommands ?? CheckCommands(ggLog: ggLog),
        super(
          name: 'push',
          description: 'Checks if code is ready to push.',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    ggLog(yellow('Can push?'));
    await _checkCommands.isUpgraded.exec(
      directory: directory,
      ggLog: ggLog,
    );
    await _checkCommands.isCommitted.exec(
      directory: directory,
      ggLog: ggLog,
    );
  }

  // ...........................................................................
  final CheckCommands _checkCommands;
}

// .............................................................................
/// A mocktail mock
class MockPush extends mocktail.Mock implements Push {}
