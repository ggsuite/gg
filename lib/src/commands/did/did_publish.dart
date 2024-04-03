// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/src/tools/did_command.dart';

/// Saves the current state of the source code
class DidPublish extends DidCommand {
  /// Constructor
  DidPublish({
    super.name = 'publish',
    super.description = 'Informs if everything is published.',
    super.shortDescription = 'Did publish',
    super.suggestion = 'Not yet published. Please run »gg do publish«.',
    super.stateKey = 'doPublish',
    required super.ggLog,
  });
}
