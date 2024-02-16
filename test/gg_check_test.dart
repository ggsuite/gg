// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/gg_check.dart';
import 'package:test/test.dart';

void main() {
  group('GgCheck', () {
    test('should work fine', () {
      final logMessages = <String>[];
      final ggCheck = GgCheck(log: logMessages.add);
      expect(ggCheck.subcommands.length, 5);
    });
  });
}
