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
class CheckState {
  /// Constructor
  CheckState({
    required this.ggLog,
    IsCommitted? isCommitted,
    HeadHash? headHash,
  })  : _isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        _headHash = headHash ?? HeadHash(ggLog: ggLog);

  // ...........................................................................
  /// The logger used for logging
  final GgLog ggLog;

  // ...........................................................................
  /// Returns previously set value
  Future<bool> get({
    required String stage,
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Read cached success hash
    final successHead = await _ggJson.readFile<String>(
      file: _configFile(directory: directory),
      path: _successHashPath(stage).join('/'),
    );

    // Get current hash
    final currentHash = await _headHash.get(directory: directory, ggLog: ggLog);

    // Compare hashes
    if (successHead == currentHash) {
      return true;
    }

    return false;
  }

  // ...........................................................................
  /// Writes the state of this command to the cache
  Future<void> set({
    required Directory directory,
    required bool success,
  }) async {
    if (!success) {
      await _removeSavedValue(directory: directory);
      return;
    }

    await _checkCheckJsonIsInGitIgnore(directory);
    await _checkIsFlutterOrDartProject(directory);
    await _checkEverythingIsCommitted(directory);

    // ................
    // Update yaml file
    final currentHash = await _headHash.get(directory: directory, ggLog: ggLog);
    final doc = await _readConfig(directory: directory);
    _updateJsonValue(
      doc,
      _successHashPath,
      currentHash,
    );
    await _writeToFile(directory: directory, doc: doc);
  }

  // ######################
  // Private
  // ######################

  final IsCommitted _isCommitted;
  final HeadHash _headHash;
  final _ggJson = const GgJson();
  const _commitMessagePrefix = '✅ Check: 1.0.0+36';

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
}

/// Mock for [CheckState]
class MockCheckState extends Mock implements CheckState {}
