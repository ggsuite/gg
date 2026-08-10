// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:path/path.dart' as path;

/// The mode of the project that `gg` is invoked in.
enum ProjectMode {
  /// A gg multi-repo workspace (contains `.ocean` — or the legacy
  /// `.master`, still recognized until gg_multi auto-renames it — or
  /// `tickets`).
  workspace,

  /// A single project: a Dart or TypeScript project (`pubspec.yaml`,
  /// `package.json`, or `tsconfig.json`) or any git repository (`.git`)
  /// found while walking up the directory tree.
  single,

  /// Neither a workspace nor a recognized single project.
  unknown,
}

/// Detects whether the current directory belongs to a gg workspace or a
/// single project (a Dart/TypeScript project or a plain git repository).
class ProjectDetector {
  /// Walks up from [workingDir] (defaults to [Directory.current]) and returns
  /// the detected [ProjectMode]. Workspace markers take precedence over
  /// single-project markers.
  static ProjectMode detect({String? workingDir}) {
    // coverage:ignore-start
    workingDir ??= Directory.current.path;
    // coverage:ignore-end

    // Repos checked out inside the ocean (.ocean/<repo>) are
    // standalone projects, not part of a ticket workspace. The legacy
    // `.master` name counts too: the detector runs before gg_multi's
    // auto-rename gets a chance to fire.
    if (!_isInsideDir(workingDir, _oceanFolder) &&
        !_isInsideDir(workingDir, _legacyMasterFolder) &&
        _walkUpFor(workingDir, _workspaceMarkers, isDirectory: true)) {
      return ProjectMode.workspace;
    }
    if (_walkUpFor(workingDir, _singleProjectMarkers, isDirectory: false)) {
      return ProjectMode.single;
    }
    // A plain git repository - possibly still empty, without any pubspec.yaml
    // or package.json - is a standalone project too.
    if (_walkUpFor(workingDir, _repoMarkers, isDirectory: null)) {
      return ProjectMode.single;
    }
    return ProjectMode.unknown;
  }

  /// The ocean folder holding the pristine clones of all repos.
  static const _oceanFolder = '.ocean';

  /// The former name of [_oceanFolder]. Still recognized so an unmigrated
  /// workspace is not mistaken for »no workspace at all«.
  static const _legacyMasterFolder = '.master';

  static const _workspaceMarkers = <String>[
    _oceanFolder,
    _legacyMasterFolder,
    'tickets',
  ];

  static const _singleProjectMarkers = <String>[
    'pubspec.yaml',
    'package.json',
    'tsconfig.json',
  ];

  /// `.git` is a directory in a normal clone and a file in a git worktree or
  /// submodule, so both entity types count.
  static const _repoMarkers = <String>['.git'];

  static bool _isInsideDir(String startPath, String dirName) {
    var dir = Directory(startPath).absolute;
    while (true) {
      if (path.basename(dir.path) == dirName) {
        return true;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return false;
      }
      dir = parent;
    }
  }

  /// Walks up from [startPath] looking for any of [markers]. [isDirectory]
  /// selects the expected entity type; `null` accepts a file or a directory.
  static bool _walkUpFor(
    String startPath,
    List<String> markers, {
    required bool? isDirectory,
  }) {
    var dir = Directory(startPath).absolute;
    while (true) {
      for (final marker in markers) {
        final markerPath = path.join(dir.path, marker);
        final exists = switch (isDirectory) {
          true => Directory(markerPath).existsSync(),
          false => File(markerPath).existsSync(),
          null =>
            Directory(markerPath).existsSync() || File(markerPath).existsSync(),
        };
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

/// Top-level subcommand names that run independently of the detected
/// project mode and are therefore never guarded.
const Set<String> modeIndependentCommands = {'one', 'multi', 'run', 'help'};

/// Command paths (`<command> <subcommand>`) that create or bootstrap a
/// workspace and therefore must run outside of one as well.
const Set<String> modeIndependentCommandPaths = {'do init'};

/// Checks whether [args] may run in the detected project mode.
///
/// All gg_multi subcommands are registered at the root of `gg`, so inside
/// a gg ticket workspace the args pass through unchanged and gg multi runs
/// by default. Inside a standalone project a [StateError] asks the user to
/// call `gg one ...` explicitly; when no project is detected at all, a
/// [StateError] points to `gg do init`. Empty args, pure flags (`--help`)
/// and [modeIndependentCommands] always pass through, and so do the
/// `<command> <subcommand>` combinations listed in
/// [modeIndependentCommandPaths].
List<String> checkArgsForProjectMode(
  List<String> args,
  ProjectMode Function() detectMode,
) {
  final firstNonFlag = args.indexWhere((a) => !a.startsWith('-'));
  if (firstNonFlag < 0) return args;

  final command = args[firstNonFlag];
  if (modeIndependentCommands.contains(command)) return args;

  final rest = args.sublist(firstNonFlag + 1);
  final secondNonFlag = rest.indexWhere((a) => !a.startsWith('-'));
  if (secondNonFlag >= 0 &&
      modeIndependentCommandPaths.contains('$command ${rest[secondNonFlag]}')) {
    return args;
  }

  switch (detectMode()) {
    case ProjectMode.workspace:
      return args;
    case ProjectMode.single:
      final oneCommand = [
        'gg',
        ...args.sublist(0, firstNonFlag),
        'one',
        ...args.sublist(firstNonFlag),
      ].join(' ');
      throw StateError(
        cError(
          'This is a standalone project. Please use '
          '${cCmd(oneCommand)}'
          ' instead.',
        ),
      );
    case ProjectMode.unknown:
      // Nothing is broken — the user is simply standing in a folder that is
      // not a workspace yet. That is an instruction to follow, not an error.
      // The three colors are concatenated rather than nested: a cCmd inside
      // a cAction resets the yellow and the rest of the sentence loses it.
      throw StateError(
        '${cError('Not a workspace. ')}'
        '${cAction('Use ')}'
        '${cCmd('gg do init')}'
        '${cAction(' to init a workspace.')}',
      );
  }
}
