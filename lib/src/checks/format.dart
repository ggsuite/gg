// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/tools/shell_cmd.dart';

/// Format
class Format extends Command<dynamic> {
  /// Constructor
  Format({
    required this.log,
  });

  // ...........................................................................
  @override
  final name = 'format';
  @override
  final description = 'Formats code.';

  /// Example instance for test purposes
  factory Format.example({
    void Function(String msg)? log,
  }) =>
      Format(
        log: log ?? (_) {}, // coverage:ignore-line
      );

  @override
  Future<void> run() async {
    await ShellCmd(
      name: 'format',
      command: 'dart format lib --output=none --set-exit-if-changed',
      message: 'dart format',
      log: log,
    ).run();
  }

  /// The log function
  final void Function(String message) log;
}
