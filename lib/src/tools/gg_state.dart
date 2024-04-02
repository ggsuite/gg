// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:gg_json/gg_json.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';

/// Stores and retrieves the state of the check commands
class GgState {
  /// Constructor
  GgState({
    required this.ggLog,
    LastChangesHash? lastChangesHash,
    IsCommitted? isCommitted,
  }) : _lastChangesHash = lastChangesHash ?? LastChangesHash(ggLog: ggLog);

  // ...........................................................................
  /// The logger used for logging
  final GgLog ggLog;

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
      ignoreFiles: ['.gg.json'],
    );

    // If no config file exists, return false
    final fileExists =
        await File(_configFile(directory: directory).path).exists();

    if (!fileExists) {
      return false;
    }

    // Get the hash written to .gg.json
    final hashInCheckJson = await _ggJson.readFile<int>(
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
    final currentHash = await _lastChangesHash.get(
      directory: directory,
      ggLog: ggLog,
      ignoreFiles: ['.gg.json'],
    );

    // Write the hash to .gg.json
    await _ggJson.writeFile(
      file: _configFile(directory: directory),
      path: _hashPath(key).join('/'),
      value: currentHash,
    );
  }

  // ######################
  // Private
  // ######################

  final LastChangesHash _lastChangesHash;
  final _ggJson = const GgJson();

  // ...........................................................................
  List<String> _hashPath(String name) => [name, 'success', 'hash'];

  // ...........................................................................
  File _configFile({
    required Directory directory,
  }) {
    final filePath = join(directory.path, '.gg.json');
    final file = File(filePath);
    return file;
  }
}

/// Mock for [GgState]
class MockCheckState extends Mock implements GgState {}
