// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_test/gg_test.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################

/// Runs dart analyze on the source code
class Analyze extends DirCommand<void> {
  /// Constructor
  Analyze({
    required super.ggLog,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(name: 'analyze', description: 'Runs »dart analyze«.');

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    await check(directory: directory);

    final statusPrinter = GgStatusPrinter<ProcessResult>(
      ggLog: ggLog,
      message: 'Running "dart analyze"',
    );

    statusPrinter.logStatus(GgStatusPrinterStatus.running);

    final result = await processWrapper.run(
      'dart',
      ['analyze', '--fatal-infos', '--fatal-warnings'],
      workingDirectory: directory.path,
    );

    statusPrinter.logStatus(
      result.exitCode == 0
          ? GgStatusPrinterStatus.success
          : GgStatusPrinterStatus.error,
    );

    if (result.exitCode != 0) {
      final files = [
        ...ErrorInfoReader().filePathes(result.stderr as String),
        ...ErrorInfoReader().filePathes(result.stdout as String),
      ];

      // Log hint
      ggLog(yellow('There are analyzer errors:'));

      // Log files
      final filesRed = files.map((e) => red('- $e')).join('\n');
      ggLog(filesRed);

      throw Exception(
        '"dart analyze" failed. See log for details.',
      );
    }
  }

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}

// .............................................................................
/// A mocktail mock
class MockAnalyze extends mocktail.Mock implements Analyze {}
