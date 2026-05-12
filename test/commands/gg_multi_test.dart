// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;
import 'package:gg/src/commands/gg_multi.dart';
import 'package:test/test.dart';

void main() {
  group('GgMultiNamespace', () {
    late GgMultiNamespace command;
    late List<String> messages;
    late GgLog ggLog;

    setUp(() {
      messages = <String>[];
      ggLog = messages.add;
      command = GgMultiNamespace(ggLog: ggLog);
    });

    test('returns the expected name', () {
      expect(command.name, 'multi');
    });

    test('returns the expected description', () {
      expect(command.description, 'Provides access to gg_multi subcommands.');
    });

    test('registers all gg_multi subcommands', () {
      final expected = gg_multi.GgMulti(ggLog: ggLog).subcommands;

      expect(command.subcommands.keys, expected.keys);
      expect(command.subcommands, hasLength(expected.length));
    });
  });
}
