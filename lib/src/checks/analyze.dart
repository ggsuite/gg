// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/tools/shell_cmd.dart';

/// Analyze
class Analyze extends Command<dynamic> {
  /// Constructor
  Analyze({
    required this.log,
    required this.isGitHub,
  });

  // ...........................................................................
  @override
  final name = 'analyze';
  @override
  final description = 'Analyzes code.';

  /// Example instance for test purposes
  factory Analyze.example({
    void Function(String msg)? log,
    bool? isGitHub,
  }) =>
      Analyze(log: log ?? (_) {}, isGitHub: isGitHub ?? false);

  @override
  Future<void> run({bool isTest = false}) async {
    if (isTest) {
      return;
    }

    // coverage:ignore-start
    await ShellCmd(
      name: 'analyze',
      command: 'dart analyze --fatal-infos --fatal-warnings',
      message: 'dart analyze',
      log: log,
    ).run();
    // coverage:ignore-end
  }

  /// The log function
  final void Function(String message) log;

  /// Running in github?
  final bool isGitHub;
}
