#!/usr/bin/env dart
// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';

export 'package:gg/gg.dart' show runGg;

// .............................................................................
// coverage:ignore-start
Future<void> main(List<String> args) async {
  exitCode = await runGg(args: args, ggLog: print);
}

// coverage:ignore-end
