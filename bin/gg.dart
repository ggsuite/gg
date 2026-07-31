#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;

// .............................................................................
Future<void> runGg({
  required List<String> args,
  required GgLog ggLog,
  ProjectMode Function()? detectMode,
}) async {
  // gg_multi stamps and checks this version in .gg/.ticket.json markers.
  gg_multi.ggCliVersion = ggVersion;

  if (args.contains('--version')) {
    ggLog(ggVersion);
    return;
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
  } on StateError catch (e) {
    ggLog(e.message);
  } catch (e) {
    ggLog(e.toString());
  }
}

// .............................................................................
// coverage:ignore-start
Future<void> main(List<String> args) => runGg(args: args, ggLog: print);
// coverage:ignore-end
