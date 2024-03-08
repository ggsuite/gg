// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_status_printer/gg_status_printer.dart';

// #############################################################################

/// Runs dart analyze on the source code
class Analyze extends GgDirCommand {
  /// Constructor
  Analyze({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  });

  /// Then name of the command
  @override
  final name = 'analyze';

  /// The description of the command
  @override
  final description = 'Runs »dart analyze«.';

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> run() async {
    await super.run();
    await GgDirCommand.checkDir(directory: inputDir);

    // Init status printer
    final statusPrinter = GgStatusPrinter<void>(
      message: 'Running "dart analyze"',
      printCallback: log,
      useCarriageReturn: isGitHub,
    );

    statusPrinter.status = GgStatusPrinterStatus.running;

    final result = await processWrapper.run(
      'dart',
      ['analyze', '--fatal-infos', '--fatal-warnings'],
      workingDirectory: inputDir.path,
    );

    statusPrinter.status = result.exitCode == 0
        ? GgStatusPrinterStatus.success
        : GgStatusPrinterStatus.error;

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

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}
