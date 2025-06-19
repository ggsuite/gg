// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'package:gg/gg.dart';
import 'package:gg_merge/gg_merge.dart' as gg_merge;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late MockCanMerge canMerge;
  late gg_merge.MockDoMerge merge;
  late DoMerge doMerge;
  final messages = <String>[];
  final ggLog = messages.add;

  setUp(() async {
    d = await Directory.systemTemp.createTemp('do_merge');
    registerFallbackValue(d);
    canMerge = MockCanMerge();
    merge = gg_merge.MockDoMerge();
    when(() => canMerge.exec(directory: d, ggLog: ggLog)).thenAnswer((_) async {
      messages.add('check allowed');
      return;
    });
    when(
      () => merge.get(directory: d, ggLog: ggLog, automerge: false),
    ).thenAnswer((_) async {
      messages.add('do merge!');
      messages.add('✅ Merge operation successfully started.');
      return true;
    });

    doMerge = DoMerge(ggLog: ggLog, canMerge: canMerge, doMerge: merge);
    messages.clear();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('DoMerge', () {
    test('should call canMerge and then doMerge', () async {
      await doMerge.exec(directory: d, ggLog: ggLog);
      expect(messages, contains('check allowed'));
      expect(messages, contains('do merge!'));
      expect(
        messages.any(
          (m) => m.contains('✅ Merge operation successfully started.'),
        ),
        isTrue,
      );
    });

    test('should propagate errors from canMerge', () async {
      when(
        () => canMerge.exec(directory: d, ggLog: ggLog),
      ).thenThrow(Exception('not allowed'));
      late String error;
      try {
        await doMerge.exec(directory: d, ggLog: ggLog);
      } catch (e) {
        error = e.toString();
      }
      expect(error, contains('not allowed'));
    });

    test('should delegate automerge flag to _doMerge', () async {
      when(
        () => merge.get(directory: d, ggLog: ggLog, automerge: true),
      ).thenAnswer((_) async {
        messages.add('do automerge merge!');
        return true;
      });
      await doMerge.get(directory: d, ggLog: ggLog, automerge: true);
      expect(messages, contains('do automerge merge!'));
    });

    test('default constructor uses correct name and description', () {
      final doMerge = DoMerge(ggLog: ggLog);
      expect(doMerge.name, 'merge');
      expect(
        doMerge.description,
        'Checks and performs merge/Pull-Request to main.',
      );
    });
  });
}
