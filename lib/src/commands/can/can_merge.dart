// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg/gg.dart';
import 'package:gg_merge/gg_merge.dart' as gg_merge;
import 'package:gg_args/gg_args.dart';

/// Are all preconditions for merging to main fulfilled?
class CanMerge extends CommandCluster {
  /// Constructor
  CanMerge({
    required super.ggLog,
    gg_merge.CanMerge? canMerge,
    super.name = 'merge',
    super.description = 'Are all preconditions for merging main fulfilled?',
    super.shortDescription = 'Can merge?',
    super.stateKey = 'canMerge',
  }) : super(commands: [canMerge ?? gg_merge.CanMerge(ggLog: ggLog)]);
}

/// A mocktail mock
class MockCanMerge extends MockDirCommand<void> implements CanMerge {}
