// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/src/commands/did/did_push.dart';
import 'package:gg/src/tools/did_command.dart';

/// Saves the current state of the source code
class DidPublish extends DidCommand {
  /// Constructor
  DidPublish({
    super.name = 'publish',
    super.description = 'Informs if everything is published.',
    super.question = 'Did run »gg do publish«?',
    required super.ggLog,
    super.isCommitted,
    super.headHash,
    DidPush? didPush,
  }) : super(predecessors: [didPush ?? DidPush(ggLog: ggLog)]);
}
