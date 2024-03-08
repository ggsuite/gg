// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_args/gg_args.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_status_printer/gg_status_printer.dart';

// #############################################################################
typedef _TaskResult = (int, List<String>, List<String>);

// #############################################################################

/// Runs dart pana on the source code
class Pana extends GgDirCommand {
  /// Constructor
  Pana({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  });

  /// Then name of the command
  @override
  final name = 'pana';

  /// The description of the command
  @override
  final description = 'Runs »dart run pana«.';

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> run() async {
    await super.run();
    await GgDirCommand.checkDir(directory: inputDir);

    // Init status printer
    final statusPrinter = GgStatusPrinter<void>(
      message: 'Running "dart pana"',
      printCallback: log,
      useCarriageReturn: isGitHub,
    );

    statusPrinter.status = GgStatusPrinterStatus.running;

    // Announce the command
    final result = await _task();
    final (code, messages, errors) = result;
    final success = code == 0;

    statusPrinter.status =
        success ? GgStatusPrinterStatus.success : GgStatusPrinterStatus.error;

    if (!success) {
      _logErrors(messages, errors);
    }

    if (code != 0) {
      throw Exception(
        '"dart run pana" failed. See log for details.',
      );
    }
  }

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;

  // ...........................................................................
  void _logErrors(List<String> messages, List<String> errors) {
    final errorMsg = errors.where((e) => e.isNotEmpty).join('\n');
    final stdoutMsg = messages.where((e) => e.isNotEmpty).join('\n');

    if (errorMsg.isNotEmpty) {
      log(errorMsg); // coverage:ignore-line
    }
    if (stdoutMsg.isNotEmpty) {
      log(stdoutMsg);
    }
  }

  // ...........................................................................
  List<String> _readProblems(Map<String, dynamic> jsonOutput) {
    final problems = <String>[];
    final sections = jsonOutput['report']['sections'] as List<dynamic>;
    final failedSections =
        sections.where((section) => section['status'] == 'failed');

    for (final section in failedSections) {
      final summary = section['summary'] as String;
      final errorPoints = summary.split('###').where(
            (element) => element.contains('[x]'),
          );

      for (final errorPoint in errorPoints) {
        final parts = errorPoint.split('\n').map(
              (e) => e.trim(),
            );

        final title = parts.first;
        final details = parts.skip(1);

        final titleRed = '$red$title$reset';
        final detailsGray = details
            .map(
              (e) => '$brightBlack$e$reset',
            )
            .join('\n');
        problems.add('\n$titleRed$detailsGray');
      }
    }
    return problems;
  }

// ...........................................................................
  Future<_TaskResult> _task() async {
    // Run 'pana' and capture the output
    final result = await processWrapper.run(
      'dart',
      [
        'run',
        'pana',
        '--no-warning',
        '--json',
        '--no-dartdoc', // dartdoc is enforced using analysis_options.yaml
      ],
      workingDirectory: inputDir.path,
    );

    try {
      // Parse the JSON output to get the score
      final jsonOutput =
          jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final grantedPoints = jsonOutput['scores']['grantedPoints'];
      final maxPoints = jsonOutput['scores']['maxPoints'];
      final complete = grantedPoints == maxPoints;
      final points = '$grantedPoints/$maxPoints';

      // Check if the score is less than 140
      if (!complete) {
        final errors = _readProblems(jsonOutput);

        return (1, <String>[], errors);
      } else {
        final messages = [
          'All pub points achieved: $points',
        ];
        return (0, <String>[], messages);
      }
    } catch (e) {
      return (1, ['Error parsing pana output: $e'], <String>[]);
    }
  }
}
