// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_direct_json/gg_direct_json.dart';
import 'package:gg_log/gg_log.dart';
import 'package:path/path.dart';

/// Stores and retrieves the state of the check commands
class GgState {
  /// Constructor
  GgState({
    required this.ggLog,
    LastChangesHash? lastChangesHash,
    IsCommitted? isCommitted,
    IsPushed? isPushed,
    ModifiedFiles? modifiedFiles,
    Commit? commit,
    HeadMessage? headMessage,
    HasRemote? hasRemote,
    CommitCount? commitCount,
  }) : _lastChangesHash = lastChangesHash ?? LastChangesHash(ggLog: ggLog),
       _isPushed = isPushed ?? IsPushed(ggLog: ggLog),
       _modifiedFiles = modifiedFiles ?? ModifiedFiles(ggLog: ggLog),
       _commit = commit ?? Commit(ggLog: ggLog),
       _headMessage = headMessage ?? HeadMessage(ggLog: ggLog),
       _hasRemote = hasRemote ?? HasRemote(ggLog: ggLog),
       _commitCount = commitCount ?? CommitCount(ggLog: ggLog);

  // ...........................................................................
  /// The logger used for logging
  final GgLog ggLog;

  // ...........................................................................
  /// The file that might be ignored while reading the hash
  static const ignoreFiles = ['.gg.json', 'CHANGELOG.md'];

  // ...........................................................................
  /// Returns previously set value
  Future<bool> readSuccess({
    required Directory directory,
    required String key,
    required GgLog ggLog,
  }) async {
    // Get the last changes hash
    final changesHash = await _lastChangesHash.get(
      directory: directory,
      ggLog: ggLog,
      ignoreFiles: ignoreFiles,
    );

    // If no config file exists, return false
    final fileExists = await File(
      _configFile(directory: directory).path,
    ).exists();

    if (!fileExists) {
      return false;
    }

    // Get the hash written to .gg.json
    final hashInCheckJson = await DirectJson.readFile<int>(
      file: _configFile(directory: directory),
      path: _hashPath(key).join('/'),
    );

    // Compare the two hashes
    // If they are the same, return true.
    // If they are different, return false.
    return changesHash == hashInCheckJson;
  }

  // ...........................................................................
  /// Updates .gg.json and writes the success state for this key.
  Future<void> writeSuccess({
    required Directory directory,
    required String key,
  }) async {
    // Nothing committed so far? Do nothing.
    await _checkCommitsAvailable(directory, ggLog);

    // If success is already written, return
    final isWritten = await readSuccess(
      directory: directory,
      key: key,
      ggLog: ggLog,
    );
    if (isWritten) {
      return;
    }

    // Get the hash of the current commit
    final hash = await currentHash(directory: directory, ggLog: ggLog);

    // Write the hash to .gg.json
    await DirectJson.writeFile(
      file: _configFile(directory: directory),
      path: _hashPath(key).join('/'),
      value: hash,
    );

    // Ammend changes to .gg.json
    await _commitOrAmmendStateChanges(directory);
  }

  // ...........................................................................
  /// Returns the current hash of the last changes
  Future<int> currentHash({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    return await _lastChangesHash.get(
      directory: directory,
      ggLog: ggLog,
      ignoreFiles: ignoreFiles,
    );
  }

  // ...........................................................................
  /// Replaces the hash in .gg.json with the current hash
  Future<void> updateHash({
    required int hash,
    required Directory directory,
  }) async {
    final current = await currentHash(directory: directory, ggLog: ggLog);
    if (current == hash) {
      return;
    }

    final ggJsonFile = _configFile(directory: directory);

    if (!await ggJsonFile.exists()) {
      return;
    }

    final ggJSonFileContent = (await ggJsonFile.readAsString()).replaceAll(
      '$hash',
      '$current',
    );
    await ggJsonFile.writeAsString(ggJSonFileContent);
  }

  // ...........................................................................
  /// Resets the success state
  Future<void> reset({required Directory directory}) async {
    await _configFile(directory: directory).writeAsString('{}');
  }

  // ######################
  // Private
  // ######################

  final LastChangesHash _lastChangesHash;

  final IsPushed _isPushed;
  final ModifiedFiles _modifiedFiles;
  final Commit _commit;
  final HeadMessage _headMessage;
  final HasRemote _hasRemote;
  final CommitCount _commitCount;

  // ...........................................................................
  List<String> _hashPath(String name) => [name, 'success', 'hash'];

  // ...........................................................................
  File _configFile({required Directory directory}) {
    final filePath = join(directory.path, '.gg.json');
    final file = File(filePath);
    return file;
  }

  // ...........................................................................
  Future<void> _commitOrAmmendStateChanges(Directory directory) async {
    // Check if only .gg.json is currently changed
    final modifiedFiles = await _modifiedFiles.get(
      directory: directory,
      ggLog: ggLog,
    );

    // If nothing changed, return
    if (modifiedFiles.isEmpty) {
      return;
    }

    final onlyGgJsonChanged =
        modifiedFiles.length == 1 && modifiedFiles.first == '.gg.json';

    // Remember if everything is committed and pushed
    final everythingWasCommitted = onlyGgJsonChanged;

    // If not everything was committed before, return here.
    //  gg.json will be committed with the next commit.
    if (!everythingWasCommitted) {
      return;
    }

    // ...................................
    // Otherwise commit or ammend .gg.json

    // Check if the repository has a remote
    final hasRemote = await _hasRemote.get(directory: directory, ggLog: ggLog);

    final everythingWasPushed = hasRemote && await _wasPushed(directory);

    // ...........................
    // To have a clean git history,
    // we will ammend changes to .gg.json to the last commit.
    // - If everything was committed and pushed, create a new commit
    // - If everything was committed but not pushed, ammend to last commit
    final message = everythingWasPushed
        ? 'Add: .gg.json check results'
        : await _headMessage.get(
            directory: directory,
            ggLog: ggLog,
            throwIfNotEverythingIsCommitted: false,
          );

    await _commit.commit(
      directory: directory,
      ggLog: ggLog,
      doStage: true,
      message: message,
      ammend: !everythingWasPushed,
    );
  }

  // ...........................................................................
  Future<bool> _wasPushed(Directory directory) async {
    return await _isPushed.get(
      directory: directory,
      ggLog: (_) {},
      ignoreUnCommittedChanges: true,
    );
  }

  // ...........................................................................
  Future<void> _checkCommitsAvailable(Directory directory, GgLog ggLog) async {
    final commitCount = await _commitCount.get(
      directory: directory,
      ggLog: ggLog,
    );
    if (commitCount == 0) {
      throw Exception('There must be at least one commit in the repository.');
    }
  }
}

/// Mock for [GgState]
class MockGgState extends MockDirCommand<void> implements GgState {}
