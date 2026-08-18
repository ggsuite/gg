// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_log/gg_log.dart';
import 'package:gg/src/commands/gg_dna.dart';
import 'package:helix/helix.dart' as helix;
import 'package:test/test.dart';

void main() {
  group('GgDna', () {
    late GgDna command;
    late List<String> messages;
    late GgLog ggLog;

    setUp(() {
      messages = <String>[];
      ggLog = messages.add;
      command = GgDna(ggLog: ggLog);
    });

    test('returns the expected name', () {
      expect(command.name, 'dna');
    });

    test('returns the expected description', () {
      expect(command.description, 'Manage the DNA of a repo');
    });

    test('registers all helix subcommands', () {
      final expected = helix.Helix(ggLog: ggLog).subcommands;

      expect(command.subcommands.keys, expected.keys);
      expect(command.subcommands, hasLength(expected.length));
    });

    test('exposes the same subcommand names and descriptions', () {
      final expected = helix.Helix(ggLog: ggLog).subcommands;

      for (final entry in expected.entries) {
        final actual = command.subcommands[entry.key];

        expect(actual, isNotNull);
        expect(actual!.name, entry.value.name);
        expect(actual.description, entry.value.description);
      }
    });
  });
}
