// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';

/// Stores and retrieves the state of the check commands
class CheckState extends DirCommand<void> {
  /// Constructor
  CheckState({
    required super.name,
    required super.description,
    required this.question,
    required super.ggLog,
    required this.predecessors,
    IsCommitted? isCommitted,
    HeadHash? headHash,
  })  : _isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        _headHash = headHash ?? HeadHash(ggLog: ggLog);

  // ...........................................................................
  @override
  @mustCallSuper
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final messages = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: question,
      ggLog: ggLog,
    );

    final result = await printer.logTask(
      task: () => get(ggLog: messages.add, directory: directory),
      success: (success) => success,
    );

    if (!result) {
      throw Exception(brightBlack(messages.join('\n')));
    }
  }

  // ...........................................................................
  /// Returns previously set value
  Future<bool> get({required Directory directory, required GgLog ggLog}) async {
    // Check if .check.json is in .gitignore
    await _checkCheckJsonIsInGitIgnore(directory);

    // Are all predecessors successful?
    if (!await _arePredecessorsSuccessful(directory: directory, ggLog: ggLog)) {
      return false;
    }

    // Read value from cache
    final doc = await _readConfig(directory: directory);
    final lastSuccess = _value(doc, _successHashPath);
    if (lastSuccess == null) {
      return false;
    }

    // Get current hash
    final currentHash = await _headHash.get(directory: directory, ggLog: ggLog);

    // Compare hashes
    if (lastSuccess == currentHash) {
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

  // ...........................................................................
  /// The command that needs to be execute before this command
  final List<CheckState> predecessors;

  /// The question to be answered by the did command
  final String question;

  // ######################
  // Private
  // ######################

  final IsCommitted _isCommitted;
  final HeadHash _headHash;

  // ...........................................................................
  List<String> get _successHashPath => ['did', name, 'last', 'success', 'hash'];

  // ...........................................................................
  String? _value(Map<String, dynamic> doc, List<String> path) {
    var node = doc;
    for (var i = 0; i < path.length; i++) {
      final pathSegment = path[i];
      if (!node.containsKey(pathSegment)) {
        return null;
      }
      if ((i == path.length - 1)) {
        return node[pathSegment] as String;
      }
      node = node[pathSegment] as Map<String, dynamic>;
    }

    return null;
  }

  // ...........................................................................
  void _remove(Map<String, dynamic> doc, List<String> path) {
    var node = doc;
    for (int i = 0; i < path.length; i++) {
      final pathSegment = path[i];
      if (!node.containsKey(pathSegment)) {
        break;
      }

      if (i == path.length - 1) {
        node.remove(path[i]);
        break;
      }
      node = node[path[i]] as Map<String, dynamic>;
    }
  }

  // ...........................................................................
  Future<bool> _arePredecessorsSuccessful({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    var allPredecessorsAreSuccessful = true;

    // Execute all predecessors
    for (final predecessor in predecessors) {
      final subMessages = <String>[];
      late bool predecessorWasSuccessful;

      // Execute predecessor and write log to subMessages
      try {
        predecessorWasSuccessful = await predecessor.get(
          directory: directory,
          ggLog: subMessages.add,
        );
      } catch (e) {
        // If a predecessor fails, don't execute its successors.
        // Only the last predecessor in the list does catch the exception
        if (e is PredecessorException) {
          final isLastInChain = predecessors.isEmpty;
          if (!isLastInChain) {
            rethrow;
          }
        }

        predecessorWasSuccessful = false;
        subMessages.add(e.toString());
      }

      // Predecessor was not successful?
      if (!predecessorWasSuccessful) {
        var error = '';

        // Log the predecessor question with red color
        error += red(predecessor.question);

        // Log the details in dark gray color
        if (subMessages.isNotEmpty) {
          error += '\n${darkGray(subMessages.join('\n'))}';
        }

        throw PredecessorException(error);
      }

      allPredecessorsAreSuccessful &= predecessorWasSuccessful;
    }

    return allPredecessorsAreSuccessful;
  }

  // ...........................................................................
  File _configFile({
    required Directory directory,
  }) {
    final filePath = join(directory.path, '.check.json');
    final file = File(filePath);
    return file;
  }

  // ...........................................................................
  Future<Map<String, dynamic>> _readConfig({
    required Directory directory,
  }) async {
    final file = _configFile(directory: directory);
    final contents = await file.exists() ? await file.readAsString() : '{}';
    final result = json.decode(contents) as Map<String, dynamic>;
    return result;
  }

  // ...........................................................................
  Future<void> _writeToFile({
    required Directory directory,
    required Map<String, dynamic> doc,
  }) async {
    final file = _configFile(directory: directory);
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    final json = encoder.convert(doc);
    await file.writeAsString(json);
  }

  // ...........................................................................
  Future<void> _removeSavedValue({required Directory directory}) async {
    final doc = await _readConfig(directory: directory);
    _remove(doc, _successHashPath);
    await _writeToFile(directory: directory, doc: doc);
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
  void _updateJsonValue(
    Map<String, dynamic> doc,
    List<String> path,
    String value,
  ) {
    Map<String, dynamic> node = doc;

    // Create path when needed
    for (int i = 0; i < path.length; i++) {
      // Write the value into the last path segment

      if (i == path.length - 1) {
        var pathSegment = path[i];
        node[pathSegment] = value;
        break;
      }

      var pathSegment = path[i];
      var childNode = node[pathSegment] as Map<String, dynamic>?;
      if (childNode == null) {
        childNode = {};
        node[pathSegment] = childNode;
      }
      node = childNode;
    }
  }

  // ...........................................................................
  Future<void> _checkCheckJsonIsInGitIgnore(Directory d) async {
    final gitIgnore = File(join(d.path, '.gitignore'));
    if (!await gitIgnore.exists()) {
      throw Exception('No .gitignore file found.');
    }

    final gitIgnoreContent = await gitIgnore.readAsString();
    if (!gitIgnoreContent.contains(RegExp(r'.check\.json'))) {
      throw Exception('.check.json is not in .gitignore.');
    }
  }
}

/// Exception that is thrown when a predecessor did not succeed
class PredecessorException implements Exception {
  /// Constructor
  PredecessorException(this.message);

  /// The message of the exception
  final String message;

  @override
  String toString() => message;
}

/// Mock for [CheckState]
class MockCheckState extends Mock implements CheckState {}
