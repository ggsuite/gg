// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:gg_json/gg_json.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';

/// Stores and retrieves the state of the check commands
class CheckState {
  /// Constructor
  CheckState({
    required this.ggLog,
    IsCommitted? isCommitted,
    HeadHash? headHash,
    HeadMessage? headMessage,
    ModifiedFiles? modifiedFiles,
    IncreaseBuild? increaseBuild,
    FromPubspec? versionFromPubspec,
    Commit? commit,
  })  : _isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        _headHash = headHash ?? HeadHash(ggLog: ggLog),
        _headMessage = headMessage ?? HeadMessage(ggLog: ggLog),
        _modifiedFiles = modifiedFiles ?? ModifiedFiles(ggLog: ggLog),
        _increaseBuild = increaseBuild ?? IncreaseBuild(ggLog: ggLog),
        _versionFromPubspec = versionFromPubspec ?? FromPubspec(ggLog: ggLog),
        _commit = commit ?? Commit(ggLog: ggLog);

  // ...........................................................................
  /// The logger used for logging
  final GgLog ggLog;

  // ...........................................................................
  /// Returns previously set value
  Future<bool> readSuccess({
    required Directory directory,
    required String stage,
    required GgLog ggLog,
  }) async {
    /// Throw if directory is not a flutter or dart project
    await _checkIsFlutterOrDartProject(directory);

    // Throw if not everything is committed
    await _checkEverythingIsCommitted(directory);

    // Read the current commit message
    final headMessage =
        await _headMessage.get(directory: directory, ggLog: ggLog);

    // Does current commit message have the check prefix?
    bool isCheckCommitMessage = _isCheckCommit(headMessage);

    // No? Return false.
    if (!isCheckCommitMessage) {
      return false;
    }

    // Yes? Get the hash of the commit before the current one.
    final previousHash = await _headHash.get(
      directory: directory,
      ggLog: ggLog,
      offset: 1,
    );

    // Get the hash written to .check.json
    final hashInCheckJson = await _ggJson.readFile<String>(
      file: _configFile(directory: directory),
      path: _successHashPath(stage).join('/'),
    );

    // Compare the two hashes
    // If they are the same, return true.
    // If they are different, return false.
    return previousHash == hashInCheckJson;
  }

  // ...........................................................................
  /// Updates .check.json and writes the success state for this stage.
  Future<void> writeSuccess({
    required Directory directory,
    required bool success,
    required String stage,
  }) async {
    await _checkIsFlutterOrDartProject(directory);
    await _checkEverythingIsCommitted(directory);

    // Get the hash of the current commit
    final currentHash = await _headHash.get(directory: directory, ggLog: ggLog);

    // Write the hash to .check.json
    await _ggJson.writeFile(
      file: _configFile(directory: directory),
      path: _successHashPath(stage).join('/'),
      value: currentHash,
    );
  }

  // ...........................................................................
  /// Commits the current state of the check command
  Future<void> commit({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Make sure only pubspec.yaml and .check.json are modified
    await _checkModifiedFiles(directory: directory, ggLog: ggLog);

    // Increase the build number in pubspec.yaml
    await _increaseBuild.exec(directory: directory, ggLog: ggLog);

    // Get the version from pubspec.yaml
    final version = await _versionFromPubspec.fromDirectory(
      directory: directory,
    );

    // Create the commit message
    final message = '✅ Check: $version';
    _isCheckCommit(message);

    // ✅ 1.0.0+45 #can-push
    // ✅ 1.0.0+144 #can-publish
    // ✅ 1.0.15+127 ⭐️ #did-publish

    // Commit the changes
    await _commit.commit(
      directory: directory,
      message: message,
      ggLog: ggLog,
      doStage: true,
    );
  }

  // ######################
  // Private
  // ######################

  final IsCommitted _isCommitted;
  final HeadHash _headHash;
  final HeadMessage _headMessage;
  final ModifiedFiles _modifiedFiles;
  final IncreaseBuild _increaseBuild;
  final FromPubspec _versionFromPubspec;
  final Commit _commit;
  final _ggJson = const GgJson();

  // ...........................................................................
  bool _isCheckCommit(String message) =>
      RegExp(r'^✅ Check: (0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$')
          .matchAsPrefix(message) !=
      null;

  // ...........................................................................
  List<String> _successHashPath(String name) =>
      ['did', name, 'last', 'success', 'hash'];

  // ...........................................................................
  File _configFile({
    required Directory directory,
  }) {
    final filePath = join(directory.path, '.check.json');
    final file = File(filePath);
    return file;
  }

  // ...........................................................................
  Future<void> _checkIsFlutterOrDartProject(Directory d) async {
    final isDartOrFlutterRoot =
        await File(join(d.path, 'pubspec.yaml')).exists();
    if (!isDartOrFlutterRoot) {
      throw Exception('Directory is not a flutter or dart project.');
    }
  }

  // ...........................................................................
  Future<void> _checkEverythingIsCommitted(Directory d) async {
    final isCommitted = await _isCommitted.get(directory: d, ggLog: ggLog);
    if (!isCommitted) {
      throw Exception('Not everything is commited.');
    }
  }

  // ...........................................................................
  Future<void> _checkModifiedFiles({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final modifiedFiles = await _modifiedFiles.get(
      directory: directory,
      ggLog: ggLog,
    );

    if (modifiedFiles.length != 2 ||
        !modifiedFiles.contains('pubspec.yaml') ||
        !modifiedFiles.contains('.check.json')) {
      throw Exception(
        'Only pubspec.yaml and .check.json should be modified.',
      );
    }
  }
}

/// Mock for [CheckState]
class MockCheckState extends Mock implements CheckState {}
