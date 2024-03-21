// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################

/// Runs dart analyze on the source code
class Analyze extends DirCommand<void> {
  /// Constructor
  Analyze({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(name: 'analyze', description: 'Runs »dart analyze«.');

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> run({Directory? directory}) async {
    final inputDir = dir(directory);
    await check(directory: inputDir);

    _logState(LogState.running);

    final result = await processWrapper.run(
      'dart',
      ['analyze', '--fatal-infos', '--fatal-warnings'],
      workingDirectory: inputDir.path,
    );

    _logState(result.exitCode == 0 ? LogState.success : LogState.error);

    if (result.exitCode != 0) {
      final files = [
        ...errorFiles(result.stderr as String),
        ...errorFiles(result.stdout as String),
      ];

      // Log hint
      log('${yellow}There are analyzer errors:$reset');

      // Log files
      final filesRed = files.map((e) => '- $red$e$reset').join('\n');
      log(filesRed);

      throw Exception(
        '"dart analyze" failed. See log for details.',
      );
    }
  }

  // .........................................................................
  void _logState(LogState state) => logState(
        log: log,
        state: state,
        message: 'Running "dart analyze"',
      );

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}

// .............................................................................
/// A mocktail mock
class MockAnalyze extends mocktail.Mock implements Analyze {}
