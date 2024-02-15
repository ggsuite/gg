// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/checks/pana.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final pana = Pana.example(log: (msg) => messages.add(msg));

  group('Pana', () {
    // #########################################################################

    // .....................................................................
    test('should run dart pana', () async {
      await pana.run(isTest: true);
    });
  });
}
