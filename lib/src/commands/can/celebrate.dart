// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:developer';
import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import '../check.dart';

/// Checks if the changes can be pushed.
class Celebrate extends DirCommand<void> {
  /// Constructor
  Celebrate({
    required super.log,
    CheckCommands? checkCommands,
  })  : _checkCommands = checkCommands ?? CheckCommands(log: log),
        super(
          name: 'celebrate',
          description:
              'Checks if everything is done and we can start the party.',
        );

  // ...........................................................................
  @override
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);
    log('${yellow}Can push?$reset');
    await _checkCommands.isPublished.run(directory: inputDir);
  }

  // ...........................................................................
  final CheckCommands _checkCommands;
}

// .............................................................................
/// A mocktail mock
class MockCelebrate extends mocktail.Mock implements Celebrate {}
