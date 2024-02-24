// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/src/tools/run_process.dart';
import 'package:test/test.dart';

void main() {
  group('RunProcess', () {
    test('should work fine', () {
      expect(defaultProcess, Process.run);
    });
  });
}
