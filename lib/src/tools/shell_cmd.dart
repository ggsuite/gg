// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:gg_check/src/tools/base_cmd.dart';

// #############################################################################
/// RunShellCmd
class ShellCmd extends BaseCmd {
  /// Constructor
  ShellCmd({
    required super.name,
    required this.command,
    required super.message,
    required super.log,
    super.exitOnError = true,
    super.exit,
  });

  // ...........................................................................
  /// The command to be executed
  final String command;

  // ...........................................................................
  /// Example instance for test purposes
  factory ShellCmd.example({
    String? name,
    String? command,
    String? message,
    void Function(String)? log,
    bool? exitOnError,
    bool? isGitHub,
    void Function(int)? exit,
  }) =>
      ShellCmd(
        name: name ?? 'showDir',
        command: command ?? 'echo hallo',
        message: message ?? 'Example command',
        log: log ?? (p0) {},
        exitOnError: exitOnError ?? false,
      );

  // ...........................................................................
  @override
  Future<(int, List<String>, List<String>)> task() async {
    final errors = <String>[];
    final messages = <String>[];

    final parts = command.split(' ');
    final cmd = parts.first;
    final List<String> arguments = parts.length > 1 ? parts.sublist(1) : [];
    var result = 0;
    try {
      final process = await Process.start(cmd, arguments);

      final stdoutCompleter = Completer<void>();
      final stderrCompleter = Completer<void>();

      process.stdout.listen(
        (event) {
          final msg = String.fromCharCodes(event);
          messages.add(msg);
        },
        onDone: () => stdoutCompleter.complete(),
        onError: (_) => stdoutCompleter.complete(), // coverage:ignore-line
      );

      process.stderr.listen(
        (event) {
          final msg = String.fromCharCodes(event);
          errors.add(msg);
        },
        onDone: () => stderrCompleter.complete(),
        onError: (_) => stderrCompleter.complete(), // coverage:ignore-line
      );

      await Future.wait([stdoutCompleter.future, stderrCompleter.future]);
      result = await process.exitCode;
    } catch (e) {
      print(e); // coverage:ignore-line
    }

    return (result, messages, errors);
  }
}
