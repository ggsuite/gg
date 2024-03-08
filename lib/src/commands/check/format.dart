// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';

// #############################################################################

/// Runs dart format on the source code
class Format extends GgDirCommand {
  /// Constructor
  Format({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  });

  /// Then name of the command
  @override
  final name = 'format';

  /// The description of the command
  @override
  final description = 'Runs »dart format«.';

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> run() async {
    await super.run();
    await GgDirCommand.checkDir(directory: inputDir);

    _logState(LogState.running);

    final result = await processWrapper.run(
      'dart',
      ['format', '.', '--fix', '--set-exit-if-changed'],
      workingDirectory: inputDir.path,
    );

    if (result.exitCode == 0) {
      _logState(LogState.success);
    }

    if (result.exitCode != 0) {
      final stdErr = result.stderr as String;
      final stdOut = result.stdout as String;
      final std = '$stdErr\n$stdOut';

      final files = errorFiles(std);

      // When running on git hub, log the file that have been changed
      if (isGitHub && files.isNotEmpty) {
        _logState(LogState.error);

        // Log hint
        log('${yellow}The following files were formatted:$reset');
        final filesRed = files.map((e) => '- $red$e$reset').join('\n');
        log(filesRed);

        throw Exception(
          'dart format failed.',
        );
      }

      // When no files have changed, but an error occurred log the error
      if (files.isEmpty) {
        _logState(LogState.error);
        log('$brightBlack$std$reset');
        throw Exception(
          'dart format failed.',
        );
      }

      _logState(LogState.success);
    }
  }

  // .........................................................................
  void _logState(LogState state) => logState(
        log: log,
        state: state,
        message: 'Running "dart format"',
      );

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}
