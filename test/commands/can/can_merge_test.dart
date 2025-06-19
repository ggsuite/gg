// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'package:gg/gg.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late CanMerge canMerge;
  final messages = <String>[];
  final ggLog = messages.add;

  setUp(() async {
    d = await Directory.systemTemp.createTemp('merge_test');
    // run git init
    await Process.run(
        'git',
        ['init', '--initial-branch=main'],
        workingDirectory: d.path
    );

    registerFallbackValue(d);

    canMerge = CanMerge(ggLog: ggLog);
    messages.clear();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('CanMerge', () {
    test('exec() runs all subcommands and logs status', () async {
      await canMerge.exec(directory: d, ggLog: ggLog);
      expect(messages[0], contains('Can merge?'));
      expect(
        messages,
        containsAll([
          'checked local',
          'checked git',
          'project updated',
          'not behind main',
          'is ahead main',
        ]),
      );
    });

    test('default constructor sets name and description', () {
      final canMerge = CanMerge(ggLog: ggLog);
      expect(canMerge.name, 'merge');
      expect(
        canMerge.description,
        'Are all preconditions for merging main fulfilled?',
      );
    });
  });
}
