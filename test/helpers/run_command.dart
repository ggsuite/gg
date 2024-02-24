// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';

/// Runs a command with the given arguments.
Future<void> runCommand({
  required Command<dynamic> cmd,
  required List<String> args,
}) async {
  final runner = CommandRunner<dynamic>('runner', 'description');
  runner.addCommand(cmd);
  await runner.run(args);
}
