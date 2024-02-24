// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:gg_check/src/checks/analyze.dart';
import 'package:gg_check/src/checks/format.dart';
import 'package:gg_check/src/checks/pana.dart';
import 'package:gg_check/src/checks/tests.dart';
import 'package:gg_check/src/tools/is_github.dart';
import 'package:yaml/yaml.dart';

// #############################################################################
const _checkYamlTemplate = '''
needsInternet: false
analyze:
  execute: true
format:
  execute: true
tests:
  execute: true
pana:
  execute: true
''';

// #############################################################################
/// The command line interface for GgCheck
class GgCheck extends Command<dynamic> {
  /// Constructor
  GgCheck({
    required this.log,
  }) {
    // Add more subcommands here
    addSubcommand(Analyze(log: log));
    addSubcommand(Format(log: log));
    addSubcommand(Tests(log: log));
    addSubcommand(Pana(log: log));
    addSubcommand(_All(this));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  // coverage:ignore-start
  @override
  final name = 'check';
  @override
  final description = 'Performs various checks on code.';
  @override
  Future<void> run() async {
    _loadConfig();
    _checkInternet();

    for (final cmd in subcommands.values) {
      if (_shouldExecute(name: cmd.name)) {
        await cmd.run();

        // Stop, if an error happend
        if (exitCode != 0) {
          exit(exitCode);
        }
      }
    }
  }

  // ...........................................................................
  late dynamic _yaml;
  void _loadConfig() {
    var file = File('check.yaml');
    if (!file.existsSync()) {
      file.writeAsStringSync(_checkYamlTemplate);
      print(
        Colorize(
          '"./check.yaml" has been created. Please edit and try again.',
        ).yellow(),
      );
      exit(1);
    }

    _yaml = loadYaml(file.readAsStringSync());
  }

  // ...........................................................................
  bool _shouldExecute({required String name}) {
    if (name == 'all') return false;

    if (_yaml[name] == null) {
      print('❌ $name not found in check.yaml. '
          'Please add configuration for it.');
      exit(1);
    }

    if (_yaml[name]['execute'] == null) {
      print('❌ $name does not have an "execute:" section. '
          'Please open check.yaml and add it to the "$name" section.');
      exit(1);
    }

    return _yaml[name]['execute'] == null || _yaml[name]['execute'] == true;
  }

  // ...........................................................................
  Future<void> _checkInternet() async {
    if (_yaml['needsInternet'] == true) {
      if (!await _hasInternet()) {
        print('❌ This package needs internet. Abort.');
        exit(1);
      }
    }
  }

  // .........................................................................
  /// Returns true if the internet is available
  Future<bool> _hasInternet() async {
    // If GitHub is not available, skip test.
    final isGitHubAvailable =
        isGitHub || (await Ping('github.com').stream.first).error == null;

    return isGitHubAvailable;
  }

  // coverage:ignore-end
}

// #############################################################################
/// The command line interface for GgCheck
class _All extends Command<dynamic> {
  _All(this.ggCheck);
  @override
  final name = 'all';
  @override
  final description = 'Runs all tests.';

  // coverage:ignore-start
  @override
  Future<void> run() async {
    await ggCheck.run();
  }
  // coverage:ignore-end

  GgCheck ggCheck;
}
