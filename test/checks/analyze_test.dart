// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/checks/analyze.dart';
import 'package:gg_check/src/tools/base_cmd.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final analyze = Analyze.example(log: (msg) => messages.add(msg));
  BaseCmd.testIsGitHub = false;

  group('Analyze', () {
    // #########################################################################

    // .....................................................................
    test('should run dart analyze', () async {
      await analyze.run(isTest: true);
    });
  });
}
