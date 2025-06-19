// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_merge/gg_merge.dart' as gg_merge;

/// Performs checks and merge/Pull-Request (PR/MR to main) in one step.
class DoMerge extends DirCommand<void> {
  /// Constructor
  DoMerge({
    required super.ggLog,
    super.name = 'merge',
    super.description = 'Checks and performs merge/Pull-Request to main.',
    CanMerge? canMerge,
    gg_merge.DoMerge? doMerge,
    GgState? state,
  }) : _canMerge = canMerge ?? CanMerge(ggLog: ggLog),
       _doMerge = doMerge ?? gg_merge.DoMerge(ggLog: ggLog),
       _state = state ?? GgState(ggLog: ggLog) {
    _addArgs();
  }

  final CanMerge _canMerge;
  final gg_merge.DoMerge _doMerge;
  final GgState _state;

  /// The key used to save the state of the command
  static const String stateKey = 'doMerge';

  bool get _automergeFromArgs => argResults?['automerge'] as bool? ?? false;

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    bool? automerge,
  }) async {
    await check(directory: directory);
    return get(directory: directory, ggLog: ggLog, automerge: automerge);
  }

  // ...........................................................................
  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    bool? automerge,
  }) async {
    automerge ??= _automergeFromArgs;
    await GgStatusPrinter<void>(
      ggLog: ggLog,
      message: 'Performing merge.',
    ).logTask(
      task: () async {
        // First, check preconditions using CanMerge
        await _canMerge.exec(directory: directory, ggLog: ggLog);
        // Now, perform/do the merge using gg_merge's DoMerge
        await _doMerge.get(
          directory: directory,
          ggLog: ggLog,
          automerge: automerge,
        );
        // Save success state
        await _state.writeSuccess(directory: directory, key: stateKey);
      },
      success: (_) => true,
    );
  }

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'automerge',
      abbr: 'a',
      help: 'Set PR/MR to automerge after CI.',
      negatable: true,
      defaultsTo: false,
    );
  }
}

/// Mock for [DoMerge]
class MockDoMerge extends MockDirCommand<void> implements DoMerge {}
