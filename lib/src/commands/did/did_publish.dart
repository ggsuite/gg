// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/tools/did_command.dart';
import 'package:gg_log/gg_log.dart';
import 'package:matcher/expect.dart';
import 'package:mocktail/mocktail.dart';

/// Everything is published to pub.dev or git?
class DidPublish extends DidCommand {
  /// Constructor
  DidPublish({
    super.name = 'publish',
    super.description = 'Everything is published to pub.dev or git?',
    super.shortDescription = 'Package is published',
    super.suggestion = 'Not yet published. Please run »gg do publish«.',
    super.stateKey = 'doPublish',
    required super.ggLog,
  });
}

/// Mock for [DidPublish]
class MockDidPublish extends Mock implements DidPublish {
  // ...........................................................................
  /// Makes [exec] successful or not
  /// Makes [exec] successful or not
  void mockSuccess({
    required bool success,
    required GgLog ggLog,
    required Directory directory,
  }) {
    when(
      () => exec(
        directory: any(
          named: 'directory',
          that: predicate<Directory>(
            (d) => d.path == directory.path,
          ),
        ),
        ggLog: any(named: 'ggLog'),
      ),
    ).thenAnswer((invocation) async {
      if (!success) {
        throw Exception('❌ Published');
      } else {
        final ggLog = invocation.namedArguments[const Symbol('ggLog')];
        ggLog('✅ Published');
      }
      return;
    });
  }
}
