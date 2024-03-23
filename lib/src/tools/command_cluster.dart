// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';

/// A cluster of commands that is run in sequence
class CommandCluster extends DirCommand<void> {
  /// Constructor
  CommandCluster({
    required super.ggLog,
    required this.commands,
    required super.name,
    required super.description,
    required this.shortDescription,
  });

  // ...........................................................................
  /// The short description printed at the beginning of each command
  final String shortDescription;

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    ggLog('$yellow$shortDescription?$reset');

    for (final command in commands) {
      await command.exec(directory: directory, ggLog: ggLog);
    }
  }

  /// The commands to run
  final List<DirCommand<void>> commands;
}
