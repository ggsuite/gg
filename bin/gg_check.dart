#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:gg_check/gg_check.dart';

// .............................................................................
Future<void> runGgCheck({
  required List<String> args,
  required void Function(String msg) log,
}) async {
  final ggCheck = GgCheck(log: log);

  try {
    // Create a command runner
    final CommandRunner<void> runner = CommandRunner<void>(
      'GgCheck',
      'Offers pre-commit checks like analyzing, linting, tests and coverage. ',
    );

    for (final cmd in ggCheck.subcommands.values) {
      runner.addCommand(cmd);
    }

    await runner.run(args);
  }

  // Print errors in red
  catch (e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    log(Colorize(msg).red().toString());
    log('Error: $e');
  }
}

// .............................................................................
Future<void> main(List<String> args) async {
  await runGgCheck(
    args: args,
    log: (msg) => print(msg),
  );
}
