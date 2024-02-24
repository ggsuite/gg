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
    Task? task,
  }) : _task = task;

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

  /// The method used to log the output
  final void Function(String) log;

  // ...........................................................................
  /// Example instance for test purposes
  factory BaseCmd.example({
    String? name,
    String? message,
    void Function(String)? log,
    void Function(int)? exit,
    Task? task,
  }) =>
      BaseCmd(
        name: name ?? 'showDir',
        message: message ?? 'Example command',
        log: log ?? (p0) {},
        task: task ?? () async => (0, ['outputs'], ['errors']),
      );

  // ...........................................................................
  /// Executes the shell command
  Future<TaskResult> run() async {
    // Announce the command
    _updateConsoleOutput(state: _State.running);
    final result = await task();
    final (code, messages, errors) = result;
    final success = code == 0;

    _updateConsoleOutput(
      state: success ? _State.success : _State.error,
    );

    if (!success) {
      _logErrors(messages, errors);
    }

    if (code != 0) {
      exitCode = code;
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
  }

  // ...........................................................................
  Task? _task;
}
