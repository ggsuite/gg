// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/checks/tests.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  group('Tests', () {
    // #########################################################################

    // .....................................................................
    test('should run dart tests', () async {
      final tests = Tests.example(log: (msg) => messages.add(msg));
      await tests.run(isTest: true);
    });
  });
}
