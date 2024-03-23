// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:developer';
import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import '../check.dart';

/// Checks if the changes can be committed.
class Commit extends DirCommand<void> {
  /// Constructor
  Commit({
    required super.ggLog,
    CheckCommands? checkCommands,
  })  : _checkCommands = checkCommands ?? CheckCommands(ggLog: ggLog),
        super(
          name: 'commit',
          description: 'Checks if code is ready to commit.',
        );

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    log('${yellow}Can commit?$reset');
    await _checkCommands.analyze.exec(directory: directory, ggLog: ggLog);
    await _checkCommands.format.exec(directory: directory, ggLog: ggLog);
    await _checkCommands.coverage.exec(directory: directory, ggLog: ggLog);
  }

  // ...........................................................................
  final CheckCommands _checkCommands;
}

// .............................................................................
/// A mocktail mock
class MockCommit extends mocktail.Mock implements Commit {}
