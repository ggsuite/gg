// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_merge/gg_merge.dart' as gg_merge;

/// Performs the merge operation.
class DoMerge extends DirCommand<void> {
  /// Constructor
  DoMerge({
    required super.ggLog,
    super.name = 'merge',
    super.description = 'Performs the merge operation.',
    GgState? state,
    gg_merge.DoMerge? doMerge,
  }) : _state = state ?? GgState(ggLog: ggLog),
       _doMerge = doMerge ?? gg_merge.DoMerge(ggLog: ggLog) {
    argParser.addFlag(
      'automerge',
      abbr: 'a',
      help: 'Set PR/MR to automerge after CI.',
      negatable: true,
      defaultsTo: false,
    );
    argParser.addFlag(
      'local',
      abbr: 'l',
      help: 'Perform a local merge instead of remote PR/MR.',
      negatable: true,
      defaultsTo: true,
    );
    argParser.addOption(
      'message',
      abbr: 'm',
      help: 'The merge commit message.',
    );
  }

  final GgState _state;
  final gg_merge.DoMerge _doMerge;

  /// The key used to save the state of the command
  final String stateKey = 'doMerge';

  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    bool? automerge,
    bool? local,
  }) => get(
    directory: directory,
    ggLog: ggLog,
    automerge: automerge,
    local: local,
  );

  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    bool? automerge,
    bool? local,
  }) async {
    automerge ??= argResults?['automerge'] as bool? ?? false;
    local ??= argResults?['local'] as bool? ?? false;
    final message = argResults?['message'] as String?;

    // Check state
    final isDone = await _state.readSuccess(
      directory: directory,
      key: stateKey,
      ggLog: ggLog,
    );

    if (isDone) {
      ggLog(yellow('Merge already performed.'));
      return;
    }

    // Perform merge using gg_merge
    await _doMerge.get(
      directory: directory,
      ggLog: ggLog,
      automerge: automerge,
      local: local,
      message: message,
    );

    // Save state
    await _state.writeSuccess(directory: directory, key: stateKey);
  }
}

/// Mock for [DoMerge].
class MockDoMerge extends MockDirCommand<void> implements DoMerge {}
