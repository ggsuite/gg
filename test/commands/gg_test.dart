#!/usr/bin/env dart

// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;
import 'package:gg/gg.dart';
import 'package:helix/helix.dart' as helix;
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

    test('registers one, multi and dna namespaces', () {
      expect(ggCommand.subcommands.keys, containsAll(['one', 'multi', 'dna']));
    });

    test('does NOT register the removed run command', () {
      expect(ggCommand.subcommands.containsKey('run'), isFalse);
    });

    test('registers all gg_multi subcommands at the root', () {
      final expected = gg_multi.GgMulti(ggLog: ggLog).subcommands.keys;
      expect(ggCommand.subcommands.keys, containsAll(expected));
    });

    test('does NOT register gg_one-only commands at the root', () {
      // `check` and `info` exist only in gg_one
      expect(ggCommand.subcommands.containsKey('check'), isFalse);
      expect(ggCommand.subcommands.containsKey('info'), isFalse);
    });

    test('hides the multi namespace in the help output', () async {
      expect(ggCommand.subcommands['multi']!.hidden, isTrue);

      await runner.run(args: []);
      final help = output.join('\n');
      expect(help, isNot(contains('Provides access to gg_multi')));
      expect(help, contains('Work in standalone repos'));
      expect(help, contains('Manage the DNA of a repo'));
    });

    test('registers the helix subcommands under dna', () {
      final expected = helix.Helix(ggLog: ggLog).subcommands.keys;
      expect(ggCommand.subcommands['dna']!.subcommands.keys, expected);
    });

    test(
      'shows gg_multi commands, "one" and "dna" in the help output',
      () async {
        await runner.run(args: []);
        final help = output.join('\n');
        final expected = [
          'one',
          'dna',
          ...gg_multi.GgMulti(ggLog: ggLog).subcommands.keys,
        ];
        for (final name in expected) {
          expect(
            help,
            matches(RegExp('^\\s+$name\\s', multiLine: true)),
            reason: '"$name" must be listed in the gg help output',
          );
        }
      },
    );
  });
}
