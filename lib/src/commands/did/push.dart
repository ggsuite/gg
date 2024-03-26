// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/src/commands/did/commit.dart';
import 'package:gg/src/tools/did_command.dart';

/// Saves the current state of the source code
class Push extends DidCommand {
  /// Constructor
  Push({
    super.name = 'push',
    super.description = 'Informs if everything is pushed.',
    super.question = 'Did run »gg do push?',
    required super.ggLog,
    super.isCommitted,
    super.headHash,
    Commit? didCommit,
  }) : super(predecessors: [didCommit ?? Commit(ggLog: ggLog)]);
}
