#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:test/test.dart';

void main() {
  final output = <String>[];
  void ggLog(String msg) => output.add(msg);

  group('GgCommand', () {
    late Gg ggCommand;
    late GgCommandRunner runner;

    setUp(() {
      output.clear();
      ggCommand = Gg(ggLog: ggLog);
      runner = GgCommandRunner(ggLog: ggLog, command: ggCommand);
    });

    test('should display usage help when no subcommand is provided', () async {
      await runner.run(args: []);
      expect(output.join('\n'), contains('Usage:'));
    });
  });
}
