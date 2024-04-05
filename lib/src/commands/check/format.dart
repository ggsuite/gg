// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_test/gg_test.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################

/// Runs dart format on the source code
class Format extends DirCommand<void> {
  /// Constructor
  Format({
    required super.ggLog,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(name: 'format', description: 'Runs »dart format«.');

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
      message: 'Running "dart format"',
    );

    statusPrinter.logStatus(GgStatusPrinterStatus.running);

    final result = await processWrapper.run(
      'dart',
      ['format', '.', '--fix', '--set-exit-if-changed'],
      workingDirectory: directory.path,
    );

    if (result.exitCode == 0) {
      statusPrinter.logStatus(GgStatusPrinterStatus.success);
    }

    if (result.exitCode != 0) {
      final stdErr = result.stderr as String;
      final stdOut = result.stdout as String;
      final std = '$stdErr\n$stdOut';

      final files = ErrorInfoReader().filePathes(std);

      // When running on git hub, log the file that have been changed
      if (isGitHub && files.isNotEmpty) {
        statusPrinter.logStatus(GgStatusPrinterStatus.error);

        // Log hint
        ggLog(yellow('The following files were formatted:'));
        final filesRed = files.map((e) => '- ${red(e)}').join('\n');
        ggLog(filesRed);

        throw Exception(
          'dart format failed.',
        );
      }

      // When no files have changed, but an error occurred log the error
      if (files.isEmpty) {
        statusPrinter.logStatus(GgStatusPrinterStatus.error);
        ggLog(brightBlack('std'));
        throw Exception(
          'dart format failed.',
        );
      }

      statusPrinter.logStatus(GgStatusPrinterStatus.success);
    }
  }

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}

// .............................................................................
/// A mocktail mock
class MockFormat extends mocktail.Mock implements Format {}
