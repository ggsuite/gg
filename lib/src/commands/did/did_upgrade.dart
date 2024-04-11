// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';

/// Are the dependencies of the package upgraded?
class DidUpgrade extends DirCommand<void> {
  /// Constructor
  DidUpgrade({
    super.name = 'upgrade',
    super.description = 'Are the dependencies of the package upgraded?',
    required super.ggLog,
    DidPublish? didPublish,
  }) : _didPublish = didPublish ?? DidPublish(ggLog: ggLog);

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    await _didPublish.exec(directory: directory, ggLog: ggLog);
  }

  // ######################
  // Private
  // ######################

  final DidPublish _didPublish;
}

/// Mock for [DidUpgrade]
class MockDidUpgrade extends Mock implements DidUpgrade {}
