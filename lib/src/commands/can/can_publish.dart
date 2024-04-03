// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/gg.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

/// Checks if the changes can be published.
class CanPublish extends CommandCluster {
  /// Constructor
  CanPublish({
    required super.ggLog,
    super.name = 'publish',
    super.description = 'Checks if code is ready to be published.',
    super.shortDescription = 'Can publish?',
    super.stateKey = 'canPublish',
    DidCommit? didCommit,
    IsVersionPrepared? isVersionPrepared,
    Pana? pana,
  }) : super(
          commands: [
            isVersionPrepared ?? IsVersionPrepared(ggLog: ggLog),
            didCommit ?? DidCommit(ggLog: ggLog),
            pana ?? Pana(ggLog: ggLog),
          ],
        );
}

// .............................................................................
/// A mocktail mock
class MockPublish extends mocktail.Mock implements CanPublish {}
