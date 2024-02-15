// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_check/src/tools/shell_cmd.dart';

/// Pana
class Pana extends Command<dynamic> {
  /// Constructor
  Pana({
    required this.log,
    required this.isGitHub,
  });

  // ...........................................................................
  @override
  final name = 'pana';
  @override
  final description = 'Runs pana.';

  /// Example instance for test purposes
  factory Pana.example({
    void Function(String msg)? log,
    bool? isGitHub,
  }) =>
      Pana(log: log ?? (_) {}, isGitHub: isGitHub ?? false);

  @override
  Future<void> run({bool? isTest}) async {
    if (isTest == true) {
      return;
    }

    // coverage:ignore-start
    await ShellCmd(
      name: 'pana',
      command: 'dart ./lib/src/checks/pana.dart',
      message: 'dart run pana',
      log: log,
    ).run();
    // coverage:ignore-end
  }

  /// The log function
  final void Function(String message) log;

  /// Running in github?
  final bool isGitHub;
}

// #############################################################################

// coverage:ignore-start

Future<void> main() async {
  // Run 'pana' and capture the output
  var process = await Process.start('dart', [
    'run',
    'pana',
    '--no-warning',
    '--json',
  ]);
  var output = await utf8.decoder.bind(process.stdout).join();
  await process.exitCode;

  try {
    // Parse the JSON output to get the score
    final jsonOutput = jsonDecode(output) as Map<String, dynamic>;
    final grantedPoints = jsonOutput['scores']['grantedPoints'];
    final maxPoints = jsonOutput['scores']['maxPoints'];
    final complete = grantedPoints == maxPoints;
    final result = '$grantedPoints/$maxPoints';

    // Check if the score is less than 140
    if (!complete) {
      print('❌ Not all pub points achieved: $result');
      print('run "dart run pana" for more details');
      exit(1);
    } else {
      print('✅ All pub points achieved: $result');
    }
  } catch (e) {
    print('Error parsing pana output: $e');
    exit(1);
  }
}

// coverage:ignore-end
