// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:gg_check/src/tools/is_github.dart';

// #############################################################################
enum _State {
  running,
  success,
  error,
}

// #############################################################################
/// A to be executed by a command
typedef TaskResult = (int, List<String>, List<String>);

/// A method defining a task to be executed
typedef Task = Future<TaskResult> Function();

// #############################################################################
/// RunBaseCmd
class BaseCmd {
  /// Constructor
  BaseCmd({
    required this.name,
    required this.message,
    required this.log,
    this.exitOnError = true,
    void Function(int)? exit,
    Task? task,
  })  : _exit = exit,
        _task = task;

  // ...........................................................................
  /// The name of the command
  final String name;

  /// The command to be executed. Returns exitCode, stdOut, stdErr
  /// Override in dervied classes
  Future<TaskResult> task() async {
    if (_task != null) {
      return _task!();
    } else {
      return (0, <String>[], <String>[]); // coverage:ignore-line
    }
  }

  /// The message to be printed when the command is executed
  final String message;

  /// If true, the command will exit on error
  final bool exitOnError;

  /// The method used to log the output
  final void Function(String) log;

  /// The method used to exit
  final void Function(int)? _exit;

  // ...........................................................................
  /// Example instance for test purposes
  factory BaseCmd.example({
    String? name,
    String? message,
    void Function(String)? log,
    bool? exitOnError,
    void Function(int)? exit,
    Task? task,
  }) =>
      BaseCmd(
        name: name ?? 'showDir',
        message: message ?? 'Example command',
        log: log ?? (p0) {},
        exitOnError: exitOnError ?? false,
        task: task ?? () async => (0, ['outputs'], ['errors']),
      );

  // ...........................................................................
  /// Executes the shell command
  Future<TaskResult> run() async {
    // Announce the command
    _updateConsoleOutput(state: _State.running);
    final result = await task();
    final (exitCode, messages, errors) = result;
    final success = exitCode == 0;

    _updateConsoleOutput(
      state: success ? _State.success : _State.error,
    );

    if (!success) {
      _logErrors(messages, errors);
    }

    return result;
  }

  // ...........................................................................
  /// Carriage return sequence
  static const carriageReturn = '\x1b[1A\x1b[2K';

  // ...........................................................................
  /// Use this property to enable github for tests
  static bool? testIsGitHub;

  // ...........................................................................
  // Log the result of the command
  void _updateConsoleOutput({required _State state}) {
    // On GitHub we have no carriage return.
    // Thus we not logging the icon the first time
    var gitHub = testIsGitHub ?? isGitHub; // coverage:ignore-line
    var cr = gitHub ? '' : BaseCmd.carriageReturn;

    final msg = switch (state) {
      _State.success => '$cr✅ $message',
      _State.error => '$cr❌ $message',
      _ => '⌛️ $message',
    };

    log(msg);
  }

  // ...........................................................................
  void _logErrors(List<String> messages, List<String> errors) {
    final errorMsg = errors.where((e) => e.isNotEmpty).join('\n');
    final stdoutMsg = messages.where((e) => e.isNotEmpty).join('\n');

    if (errorMsg.isNotEmpty) {
      log(errorMsg);
    }
    if (stdoutMsg.isNotEmpty) {
      log(stdoutMsg); // coverage:ignore-line
    }

    if (exitOnError) {
      final ex = _exit ?? exit; // coverage:ignore-line
      ex(1); // coverage:ignore-line
    }
  }

  // ...........................................................................
  Task? _task;
}
