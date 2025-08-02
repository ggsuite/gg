// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_merge/gg_merge.dart' as gg_merge;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late DoMerge doMerge;
  late MockGgMergeDoMerge mockGgMergeDoMerge;
  late MockGgState mockGgState;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitSampleFile(d);
    mockGgMergeDoMerge = MockGgMergeDoMerge();
    mockGgState = MockGgState();
    doMerge = DoMerge(
      ggLog: ggLog,
      doMerge: mockGgMergeDoMerge,
      state: mockGgState,
    );
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('DoMerge', () {
    group('constructor', () {
      test('should initialize with defaults', () {
        final instance = DoMerge(ggLog: ggLog);
        expect(instance.name, 'merge');
        expect(instance.description, 'Performs the merge operation.');
        expect(instance.stateKey, 'doMerge');
      });

      test('should initialize with provided parameters', () {
        final instance = DoMerge(
          ggLog: ggLog,
          state: mockGgState,
          doMerge: mockGgMergeDoMerge,
        );
        // Verify argParser flags are added
        expect(instance.argParser.commands.isEmpty, isTrue);
      });
    });

    test('should call gg_merge DoMerge', () async {
      when(
        () =>
            mockGgState.readSuccess(directory: d, key: 'doMerge', ggLog: ggLog),
      ).thenAnswer((_) async => false);

      when(
        () => mockGgMergeDoMerge.get(
          directory: d,
          ggLog: ggLog,
          automerge: false,
          local: false,
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockGgState.writeSuccess(directory: d, key: 'doMerge'),
      ).thenAnswer((_) async {});

      await doMerge.get(directory: d, ggLog: ggLog);

      verify(
        () => mockGgMergeDoMerge.get(
          directory: d,
          ggLog: ggLog,
          automerge: false,
          local: false,
        ),
      ).called(1);

      verify(
        () => mockGgState.writeSuccess(directory: d, key: 'doMerge'),
      ).called(1);
    });

    test('should not perform merge if already done', () async {
      when(
        () =>
            mockGgState.readSuccess(directory: d, key: 'doMerge', ggLog: ggLog),
      ).thenAnswer((_) async => true);

      await doMerge.get(directory: d, ggLog: ggLog);

      expect(messages.last, yellow('Merge already performed.'));
      verifyNever(() => mockGgMergeDoMerge.get(directory: d, ggLog: ggLog));
    });

    group('exec', () {
      test('should call get with provided parameters', () async {
        when(
          () => mockGgState.readSuccess(
            directory: d,
            key: 'doMerge',
            ggLog: ggLog,
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockGgMergeDoMerge.get(
            directory: d,
            ggLog: ggLog,
            automerge: true,
            local: true,
          ),
        ).thenAnswer((_) async => true);

        when(
          () => mockGgState.writeSuccess(directory: d, key: 'doMerge'),
        ).thenAnswer((_) async {});

        await doMerge.exec(
          directory: d,
          ggLog: ggLog,
          automerge: true,
          local: true,
        );

        verify(
          () => mockGgMergeDoMerge.get(
            directory: d,
            ggLog: ggLog,
            automerge: true,
            local: true,
          ),
        ).called(1);
      });
    });
  });
}

class MockGgMergeDoMerge extends Mock implements gg_merge.DoMerge {}

class MockGgState extends Mock implements GgState {}
