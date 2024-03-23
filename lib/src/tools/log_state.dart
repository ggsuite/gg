// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ...........................................................................
import 'package:gg_log/gg_log.dart';

import 'is_github.dart';
import 'carriage_return.dart';

/// The state of the log
enum LogState {
  /// The command is running
  running,

  /// The command was successful
  success,

  /// The command failed
  error,
}

// ...........................................................................
/// Log the result of the command
void logState({
  required LogState state,
  required String message,
  required GgLog ggLog,
}) {
  // On GitHub we have no carriage return.
  // Thus we not logging the icon the first time
  var gitHub = isGitHub;
  var cr = gitHub ? '' : carriageReturn;

  final msg = switch (state) {
    LogState.success => '$cr✅ $message',
    LogState.error => '$cr❌ $message',
    _ => '⌛️ $message',
  };

  ggLog(msg);
}
