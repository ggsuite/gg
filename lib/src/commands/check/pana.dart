// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################
typedef _TaskResult = (int, List<String>, List<String>);

// #############################################################################

/// Runs dart pana on the source code
class Pana extends DirCommand<void> {
  /// Constructor
  Pana({
    required super.ggLog,
    this.processWrapper = const GgProcessWrapper(),
    PublishTo? publishTo,
    bool? publishedOnly,
  })  : _publishTo = publishTo ?? PublishTo(ggLog: ggLog),
        _publishedOnlyFromConstructor = publishedOnly,
        super(
          name: 'pana',
          description: 'Runs »dart run pana«.',
        ) {
    _addArgs();
  }

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    bool? publishedOnly,
  }) async {
    await check(directory: directory);
    publishedOnly ??=
        _publishedOnlyFromArgs ?? _publishedOnlyFromConstructor ?? false;

    final statusPrinter = GgStatusPrinter<ProcessResult>(
      ggLog: ggLog,
      message: 'Running "dart pana"',
    );

    // Pana will only run if the package is to be published to pub.dev
    if (publishedOnly) {
      final isPublished =
          await _publishTo.fromDirectory(directory) == 'pub.dev';
      if (!isPublished) {
        statusPrinter.logStatus(GgStatusPrinterStatus.success);
        return;
      }
    }

    // Announce the command
    statusPrinter.logStatus(GgStatusPrinterStatus.running);
    final result = await _task(directory);
    final (code, messages, errors) = result;
    final success = code == 0;

    statusPrinter.logStatus(
      success ? GgStatusPrinterStatus.success : GgStatusPrinterStatus.error,
    );

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

  // ######################
  // Private
  // ######################

  final PublishTo _publishTo;

  // ...........................................................................
  void _logErrors(List<String> messages, List<String> errors) {
    final errorMsg = errors.where((e) => e.isNotEmpty).join('\n');
    final stdoutMsg = messages.where((e) => e.isNotEmpty).join('\n');

    if (errorMsg.isNotEmpty) {
      ggLog(errorMsg); // coverage:ignore-line
    }
    if (stdoutMsg.isNotEmpty) {
      ggLog(stdoutMsg);
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

        final titleRed = red(title);
        final detailsGray = details
            .map(
              (e) => brightBlack(e),
            )
            .join('\n');
        problems.add('\n$titleRed$detailsGray');
      }
    }
    return problems;
  }

// ...........................................................................
  Future<_TaskResult> _task(Directory dir) async {
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
      workingDirectory: dir.path,
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

  // ...........................................................................
  bool? get _publishedOnlyFromArgs => argResults?['published-only'] as bool?;

  // ...........................................................................
  final bool? _publishedOnlyFromConstructor;

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'published-only',
      help: 'Check only packages published to pub.dev.',
      negatable: true,
    );
  }
}

// .............................................................................
/// A mocktail mock
class MockPana extends mocktail.Mock implements Pana {}
