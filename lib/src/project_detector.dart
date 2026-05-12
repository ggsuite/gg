// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart' as path;

/// The mode of the project that `gg` is invoked in.
enum ProjectMode {
  /// A gg multi-repo workspace (contains `.master` or `tickets`).
  workspace,

  /// A single Dart or TypeScript project (`pubspec.yaml`, `package.json`,
  /// or `tsconfig.json` found while walking up the directory tree).
  single,

  /// Neither a workspace nor a recognized single project.
  unknown,
}

/// Detects whether the current directory belongs to a gg workspace or a
/// single Dart/TypeScript project.
class ProjectDetector {
  /// Walks up from [workingDir] (defaults to [Directory.current]) and returns
  /// the detected [ProjectMode]. Workspace markers take precedence over
  /// single-project markers.
  static ProjectMode detect({String? workingDir}) {
    // coverage:ignore-start
    workingDir ??= Directory.current.path;
    // coverage:ignore-end

    if (_walkUpFor(workingDir, _workspaceMarkers, isDirectory: true)) {
      return ProjectMode.workspace;
    }
    if (_walkUpFor(workingDir, _singleProjectMarkers, isDirectory: false)) {
      return ProjectMode.single;
    }
    return ProjectMode.unknown;
  }

  static const _workspaceMarkers = <String>['.master', 'tickets'];

  static const _singleProjectMarkers = <String>[
    'pubspec.yaml',
    'package.json',
    'tsconfig.json',
  ];

  static bool _walkUpFor(
    String startPath,
    List<String> markers, {
    required bool isDirectory,
  }) {
    var dir = Directory(startPath).absolute;
    while (true) {
      for (final marker in markers) {
        final markerPath = path.join(dir.path, marker);
        final exists = isDirectory
            ? Directory(markerPath).existsSync()
            : File(markerPath).existsSync();
        if (exists) {
          return true;
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return false;
      }
      dir = parent;
    }
  }
}

/// Top-level subcommand names that are shared between gg_multi and gg_one
/// and are dispatched dynamically based on the detected project mode.
const Set<String> sharedTopLevelCommands = {'can', 'did', 'do'};

/// Rewrites [args] by inserting `one` or `multi` before the first non-flag
/// argument when it is a [sharedTopLevelCommands] entry. Throws a
/// [StateError] when the mode is [ProjectMode.unknown].
List<String> rewriteArgsForProjectMode(
  List<String> args,
  ProjectMode Function() detectMode,
) {
  final firstNonFlag = args.indexWhere((a) => !a.startsWith('-'));
  if (firstNonFlag < 0) return args;

  final command = args[firstNonFlag];
  if (!sharedTopLevelCommands.contains(command)) return args;

  final before = args.sublist(0, firstNonFlag);
  final after = args.sublist(firstNonFlag);
  switch (detectMode()) {
    case ProjectMode.workspace:
      return [...before, 'multi', ...after];
    case ProjectMode.single:
      return [...before, 'one', ...after];
    case ProjectMode.unknown:
      throw StateError(
        'Cannot run "gg $command" here: the current directory is neither '
        'inside a gg workspace (no .master/tickets folder found) nor a '
        'Dart/TypeScript project (no pubspec.yaml/package.json/tsconfig.json '
        'found). Use "gg one $command ..." or "gg multi $command ..." '
        'explicitly.',
      );
  }
}
