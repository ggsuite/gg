// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_one/gg_one.dart' as gg_one;
import 'package:gg_log/gg_log.dart';
import 'package:gg/src/commands/gg_one.dart';
import 'package:test/test.dart';

void main() {
  group('GgOne', () {
    late GgOne command;
    late List<String> messages;
    late GgLog ggLog;

    setUp(() {
      messages = <String>[];
      ggLog = messages.add;
      command = GgOne(ggLog: ggLog);
    });

    test('returns the expected name', () {
      expect(command.name, 'one');
    });

    test('returns the expected description', () {
      expect(command.description, 'Provides access to gg subcommands.');
    });

    test('registers all gg subcommands', () {
      final expectedSubcommands = gg_one.Gg(ggLog: ggLog).subcommands;

      expect(command.subcommands.keys, expectedSubcommands.keys);
      expect(command.subcommands, hasLength(expectedSubcommands.length));
    });

    test('exposes the same subcommand instances by name type contract', () {
      final expectedSubcommands = gg_one.Gg(ggLog: ggLog).subcommands;

      for (final entry in expectedSubcommands.entries) {
        final actualSubcommand = command.subcommands[entry.key];

        expect(actualSubcommand, isNotNull);
        expect(actualSubcommand!.name, entry.value.name);
        expect(actualSubcommand.description, entry.value.description);
      }
    });
  });
}
