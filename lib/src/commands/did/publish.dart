// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/src/commands/did/push.dart';
import 'package:gg/src/tools/did_command.dart';

/// Saves the current state of the source code
class Publish extends DidCommand {
  /// Constructor
  Publish({
    super.name = 'publish',
    super.description = 'Informs if everything is published.',
    super.question = 'Did run »gg do publish«?',
    required super.ggLog,
    super.isCommitted,
    super.headHash,
    Push? didPush,
  }) : super(predecessors: [didPush ?? Push(ggLog: ggLog)]);
}
