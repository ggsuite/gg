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

/// Checks if the changes can be published.
class Publish extends DirCommand<void> {
  /// Constructor
  Publish({
    required super.log,
    CheckCommands? checkCommands,
  })  : _checkCommands = checkCommands ?? CheckCommands(log: log),
        super(
          name: 'publish',
          description: 'Checks if code is ready to be published.',
        );

  // ...........................................................................
  @override
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);
    log('${yellow}Can publish?$reset');
    await _checkCommands.isPushed.run(directory: inputDir);
    await _checkCommands.isVersioned.run(directory: inputDir);
    await _checkCommands.pana.run(directory: inputDir);
  }

  // ...........................................................................
  final CheckCommands _checkCommands;
}

// .............................................................................
/// A mocktail mock
class MockPublish extends mocktail.Mock implements Publish {}
