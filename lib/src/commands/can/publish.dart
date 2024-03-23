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

/// Checks if the changes can be published.
class Publish extends DirCommand<void> {
  /// Constructor
  Publish({
    required super.ggLog,
    CheckCommands? checkCommands,
  })  : _checkCommands = checkCommands ?? CheckCommands(ggLog: ggLog),
        super(
          name: 'publish',
          description: 'Checks if code is ready to be published.',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    ggLog(yellow('Can publish?'));
    await _checkCommands.isPushed.exec(
      directory: directory,
      ggLog: ggLog,
    );
    await _checkCommands.isVersioned.exec(
      directory: directory,
      ggLog: ggLog,
    );
    await _checkCommands.pana.exec(
      directory: directory,
      ggLog: ggLog,
    );
  }

  // ...........................................................................
  final CheckCommands _checkCommands;
}

// .............................................................................
/// A mocktail mock
class MockPublish extends mocktail.Mock implements Publish {}
