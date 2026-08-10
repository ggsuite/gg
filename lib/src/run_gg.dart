// @license
// Copyright (c) 2019 - 2026 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;
import 'package:gg_process/gg_process.dart';

import 'commands/gg.dart';
import 'gg_version.dart';
import 'host/gg_host.dart';
import 'project_detector.dart';

/// Runs the `gg` command line with [args] and returns the exit code.
///
/// This is the whole of `gg`: `bin/gg.dart` calls it, and so does every
/// embedder — see [GgHost] for running gg somewhere that has no `dart:io`,
/// for example as WebAssembly from Node.
///
/// Errors are reported through [ggLog] rather than thrown, and a non-zero
/// exit code is returned instead of terminating the process, so an embedder
/// stays in control of both.
Future<int> runGg({
  required List<String> args,
  required GgLog ggLog,
  ProjectMode Function()? detectMode,
}) async {
  // gg_multi stamps and checks this version in .gg/.ticket.json markers.
  gg_multi.ggCliVersion = ggVersion;

  ggExitCode = 0;

  if (args.contains('--version')) {
    ggLog(ggVersion);
    return 0;
  }

  try {
    final checked = checkArgsForProjectMode(
      args,
      detectMode ?? ProjectDetector.detect,
    );
    await GgCommandRunner(
      ggLog: ggLog,
      command: Gg(ggLog: ggLog),
    ).run(args: checked);
  } on GgExitException catch (e) {
    return e.code;
  } on StateError catch (e) {
    ggLog(e.message);
  } catch (e) {
    ggLog(e.toString());
  }

  return ggExitCode;
}
