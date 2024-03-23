// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:gg_publish/gg_publish.dart';

// .............................................................................
/// Dependencies for the check command
class Checks {
  /// Constructor
  Checks({
    required this.ggLog,
    Analyze? analyze,
    Format? format,
    Coverage? coverage,
    Pana? pana,
    IsPushed? isPushed,
    IsCommitted? isCommitted,
    IsVersioned? isVersioned,
    IsPublished? isPublished,
    IsUpgraded? isUpgraded,
  })  : analyze = analyze ?? Analyze(ggLog: ggLog),
        format = format ?? Format(ggLog: ggLog),
        coverage = coverage ?? Coverage(ggLog: ggLog),
        pana = pana ?? Pana(ggLog: ggLog),
        isPushed = isPushed ?? IsPushed(ggLog: ggLog),
        isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        isVersioned = isVersioned ?? IsVersioned(ggLog: ggLog),
        isPublished = isPublished ?? IsPublished(ggLog: ggLog),
        isUpgraded = isUpgraded ?? IsUpgraded(ggLog: ggLog) {
    _initAll();
  }

  /// The log function
  final GgLog ggLog;

  /// The analyze command
  final Analyze analyze;

  /// The format command
  final Format format;

  /// The coverage command
  final Coverage coverage;

  /// The pana command
  final Pana pana;

  /// The isPushed command
  final IsPushed isPushed;

  /// The isCommitted command
  final IsCommitted isCommitted;

  /// The isVersioned command
  final IsVersioned isVersioned;

  /// The isPublished command
  final IsPublished isPublished;

  /// The isUpgraded command
  final IsUpgraded isUpgraded;

  /// Returns a list of all commands
  Iterable<DirCommand<void>> get all => _all;

  // ...........................................................................
  late List<DirCommand<void>> _all;

  void _initAll() {
    _all = [
      analyze,
      format,
      coverage,
      pana,
      isPushed,
      isCommitted,
      isVersioned,
      isPublished,
      isUpgraded,
    ];
  }
}
