// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_log/gg_log.dart';
import 'package:gg_one/gg_one.dart' show GgPrompts;
import 'package:gg/src/commands/gg_dna.dart';
import 'package:helix/helix.dart' as helix;
import 'package:test/test.dart';

/// Prompts that record the question and answer with a fixed index.
class _FakePrompts extends GgPrompts {
  _FakePrompts(this.answer);

  final int answer;
  final List<({String prompt, List<String> options})> asked = [];

  @override
  Future<int> select({
    required String prompt,
    required List<String> options,
    int initialIndex = 0,
  }) async {
    asked.add((prompt: prompt, options: options));
    return answer;
  }

  @override
  Future<String> input({
    required String prompt,
    String? defaultValue,
    String? initialText,
    bool asMessageEditor = false,
  }) async => throw UnimplementedError();
}

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

  group('helixSelectPrompt', () {
    tearDown(() => GgPrompts.current = null);

    test('asks through the prompts of the gg suite', () async {
      final prompts = _FakePrompts(1);
      GgPrompts.current = prompts;

      final index = await helixSelectPrompt(
        prompt: 'Which?',
        options: const ['Dart', 'TypeScript'],
      );

      expect(index, 1);
      expect(prompts.asked, [
        (prompt: 'Which?', options: const ['Dart', 'TypeScript']),
      ]);
    });
  });
}
