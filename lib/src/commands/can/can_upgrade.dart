// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/gg.dart';
import 'package:mocktail/mocktail.dart';

/// Is the package ready to get a dependeny upgrade?
class CanUpgrade extends CommandCluster {
  /// Constructor
  CanUpgrade({
    required super.ggLog,
    Checks? checkCommands,
    super.name = 'upgrade',
    super.shortDescription = 'Can upgrade?',
    super.description = 'Is the package ready to get a dependeny upgrade?',
    super.stateKey = 'canUpgrade',
    DidPublish? didPublish,
  }) : super(
          commands: [
            // »gg do upgrade« will also publish the package automatically

            didPublish ?? DidPublish(ggLog: ggLog),
          ],
        );
}

// .............................................................................
/// A mocktail mock
class MockCanUpgrade extends Mock implements CanUpgrade {}
