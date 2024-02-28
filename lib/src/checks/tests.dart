// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/tools/base_cmd.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:colorize/colorize.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

// .............................................................................
typedef _Report = Map<String, Map<int, int>>;
typedef _MissingLines = Map<String, List<int>>;

/// Tests
class Tests extends Command<dynamic> {
  /// Constructor
  Tests({
    required this.log,
  });

  // ...........................................................................
  @override
  final name = 'tests';
  @override
  final description = 'Runs tests & coverage check.';

  /// Example instance for test purposes
  factory Tests.example({
    void Function(String msg)? log,
  }) =>
      Tests(log: log ?? (_) {});

  @override
  Future<void> run({bool? isTest}) async {
    if (isTest == true) {
      return;
    }

    // coverage:ignore-start
    await BaseCmd(
      name: 'tests',
      task: _task,
      message: 'gg_check tests',
      log: log,
    ).run();
    // coverage:ignore-end
  }

  /// The log function
  final void Function(String message) log;

  // ######################
  // Private
  // ######################

  final _errors = <String>[];
  final _messages = <String>[];

  // ...........................................................................
  late bool _isFlutter;
  bool _estimateFlutterOrDart() {
    final File pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw Exception('pubspec.yaml not found');
    }

    final String content = pubspec.readAsStringSync();
    return (content.contains('flutter'));
  }

// .............................................................................
  List<String> _extractErrorLines(String message) {
    // Regular expression to match file paths and line numbers
    RegExp exp = RegExp(r'test\/[\/\w]+\.dart[\s:]*\d+:\d+');
    final matches = exp.allMatches(message);
    final result = <String>[];

    if (matches.isEmpty) {
      return result;
    }

    for (final match in matches) {
      var matchedString = match.group(0) ?? '';
      result.add(matchedString);
    }

    return result;
  }

// .............................................................................
  String _makeErrorLineVscodeCompatible(String errorLine) {
    errorLine = errorLine.replaceAll(':', ' ');
    var parts = errorLine.split(' ');
    if (parts.length != 3) {
      return errorLine;
    }

    var filePath = parts[0];
    var lineNumber = parts[1];
    var columnNumber = parts[2];

    return '$filePath:$lineNumber:$columnNumber';
  }

// .............................................................................
  String _makeErrorLinesInMessageVscodeCompatible(String message) {
    var errorLines = _extractErrorLines(message);
    var result = message;

    for (var errorLine in errorLines) {
      var compatibleErrorLine = _makeErrorLineVscodeCompatible(errorLine);
      result = result.replaceAll(errorLine, compatibleErrorLine);
    }

    return result;
  }

// .............................................................................
  String _addDotSlash(String relativeFile) {
    if (!relativeFile.startsWith('./')) {
      return './$relativeFile';
    }
    return relativeFile;
  }

// .............................................................................
  _Report _generateReport() {
    return _isFlutter ? _generateFlutterReport() : _generateDartReport();
  }

  // ...........................................................................
  _Report _generateDartReport() {
    // Iterate all 'dart.vm.json' files within coverage directory
    final coverageDir = Directory('./coverage');
    final coverageFiles =
        coverageDir.listSync(recursive: true).whereType<File>().where((file) {
      return file.path.endsWith('dart.vm.json');
    });

    // Prepare result
    final result = _Report();

    // Collect coverage data
    for (final coverageFile in coverageFiles) {
      final testFile = coverageFile.path
          .replaceAll('.vm.json', '')
          .replaceAll('./coverage/', '');
      var implementationFile = testFile
          .replaceAll('test/', 'lib/src/')
          .replaceAll('_test.dart', '.dart');
      final implementationFileWithoutLib =
          implementationFile.replaceAll('lib/', '');

      final fileContent = coverageFile.readAsStringSync();
      final coverageData = jsonDecode(fileContent);

      // Iterate coverage data
      final entries = coverageData['coverage'] as List<dynamic>;
      final entriesForImplementationFile = entries.where((entry) {
        final source = entry['source'] as String;
        return (source.contains(implementationFileWithoutLib));
      });
      for (final entry in entriesForImplementationFile) {
        // Read script

        // Find or create summary for script
        implementationFile = _addDotSlash(implementationFile);
        result[implementationFile] ??= {};
        late Map<int, int> summaryForScript = result[implementationFile]!;
        final ignoredLines = _ignoredLines(implementationFile);

        // Collect hits for all lines
        var hits = entry['hits'] as List<dynamic>;
        for (var i = 0; i < hits.length; i += 2) {
          final line = hits[i] as int;
          final isIgnored = ignoredLines[line];
          if (isIgnored) continue;
          final hitCount = hits[i + 1] as int;
          // Find or create summary for line
          final existingHits = summaryForScript[line] ?? 0;
          summaryForScript[line] = existingHits + hitCount;
        }
      }
    }

    return result;
  }

  // ...........................................................................
  _Report _generateFlutterReport() {
    // Iterate all 'lcov' files within coverage directory
    final coverageFile = File('./coverage/lcov.info');

    // Prepare result
    final result = _Report();

    // Prepare report for file
    late Map<int, int> summaryForScript;

    final fileContent = coverageFile.readAsStringSync();
    final lines = fileContent.split('\n');

    for (final line in lines) {
      // Read script
      if (line.startsWith('SF:')) {
        final script = './${line.replaceFirst('SF:', '')}';
        result[script] = {};
        summaryForScript = result[script]!;
      }
      // Read coverage
      else if (line.startsWith('DA:')) {
        final parts = line.replaceFirst('DA:', '').split(',');
        final lineNumber = int.parse(parts[0]);
        final hits = int.parse(parts[1]);
        summaryForScript[lineNumber] = hits;
      }
    }

    return result;
  }

  // ...........................................................................
  double _calculateCoverage(_Report report) {
    // Calculate coverage
    var totalLines = 0;
    var coveredLines = 0;
    for (final script in report.keys) {
      for (final line in report[script]!.keys) {
        totalLines++;
        if (report[script]![line]! > 0) {
          coveredLines++;
        }
      }
    }

    // Calculate percentage
    var percentage = (coveredLines / totalLines) * 100;
    return percentage;
  }

// .............................................................................
  final Map<String, List<bool>> _ignoredLinesCache = {};

// .............................................................................
  List<bool> _ignoredLines(String script) {
    final cachedResult = _ignoredLinesCache[script];
    if (cachedResult != null) {
      return cachedResult;
    }

    final lines = File(script).readAsLinesSync();
    final ignoredLines = List<bool>.filled(lines.length + 1, false);

    // Evaluate ignore start/end
    var ignoreStart = false;
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var lineNumber = i + 1;

      // Whole file ignored?
      if (line.contains('coverage:ignore-file')) {
        ignoredLines.fillRange(0, lines.length + 1, true);
        break;
      }

      // Range ignored?
      if (line.contains('coverage:ignore-start')) {
        ignoreStart = true;
      }

      if (line.contains('coverage:ignore-end')) {
        ignoreStart = false;
      }

      // Line ignored?
      var ignoreLine = line.contains('coverage:ignore-line');
      ignoredLines[lineNumber] = ignoreStart || ignoreLine;
    }

    _ignoredLinesCache[script] = ignoredLines;
    return ignoredLines;
  }

// .............................................................................
  _MissingLines _estimateMissingLines(_Report report) {
    final _MissingLines result = {};
    for (final script in report.keys) {
      final lines = report[script]!;
      final linesSorted = lines.keys.toList()..sort();

      for (final line in linesSorted) {
        final hits = lines[line]!;
        if (hits == 0) {
          result[script] ??= [];
          result[script]!.add(line);
        }
      }
    }

    return result;
  }

// .............................................................................
  void _printMissingLines(_MissingLines missingLines) {
    for (final script in missingLines.keys) {
      final testFile = script
          .replaceFirst('lib/src', 'test')
          .replaceAll('.dart', '_test.dart');

      const bool printFirstOnly = true;
      final lineNumbers = missingLines[script]!;
      for (final lineNumber in lineNumbers) {
        // Dont print too many lines

        final message = '$script:$lineNumber';
        _messages.add('- ${Colorize(message).red()}');
        _messages.add('  ${Colorize(testFile).blue()}\n');
        if (printFirstOnly) break;
      }
    }
  }

// .............................................................................
  void _writeLcovReport(_Report report) {
    final buffer = StringBuffer();
    for (final script in report.keys) {
      buffer.writeln('SF:$script');
      for (final line in report[script]!.keys) {
        final hits = report[script]![line]!;
        buffer.writeln('DA:$line,$hits');
      }
      buffer.writeln('end_of_record');
    }

    final lcovReport = buffer.toString();
    final lcovFile = File('./coverage/lcov.info');
    lcovFile.writeAsStringSync(lcovReport);
  }

// .............................................................................
  Iterable<(File, File)> _implementationAndTestFiles() {
    // Get all implementation files
    final implementationFiles = Directory('./lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
      return file.path.endsWith('.dart');
    }).map((file) {
      // Make sure file path starts with ./
      if (!file.path.startsWith('./')) {
        return File('./${file.path}');
      }
      return file;
    });

    final result = implementationFiles.map((implementationFile) {
      final testFile = implementationFile.path
          .replaceAll('lib/src/', 'test/')
          .replaceAll('.dart', '_test.dart');

      return (implementationFile, File(testFile));
    });

    return result;
  }

// .............................................................................
  Iterable<(File, File)> _collectMissingTestFiles(
    Iterable<(File, File)> files,
  ) =>
      files.where(
        (e) => !e.$2.existsSync(),
      );

// .............................................................................
  static const _testBoilerplate = '''
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

void main() {
  group('Boilerplate', () {
    test('should work fine', () {
      // INSTANTIATE CLASS HERE
      expect(true, isNotNull);
    });
  });
}
''';

// .............................................................................
  void _createMissingTestFiles(Iterable<(File, File)> missingFiles) {
    // Create missing test files and ask user to edit it
    _messages.add(
      Colorize('Tests were created. Please revise:').yellow().toString(),
    );
    final packageName = basename(Directory.current.path);

    for (final (implementationFile, testFile) in missingFiles) {
      // Create test file with intermediate directories
      final testFileDir = dirname(testFile.path);
      Directory(testFileDir).createSync(recursive: true);

      // Write boilerplate
      final className =
          basenameWithoutExtension(implementationFile.path).pascalCase;

      final implementationFilePath =
          implementationFile.path.replaceAll('lib/', '').replaceAll('./', '');

      final boilerplate = _testBoilerplate
          .replaceAll('Boilerplate', className)
          .replaceAll('// INSTANTIATE CLASS HERE', '// const $className();')
          .replaceAll(
            'import \'package:test/test.dart\';',
            'import \'package:$packageName/'
                // ignore: missing_whitespace_between_adjacent_strings
                '$implementationFilePath\';\n'
                'import \'package:test/test.dart\';\n',
          );

      // Create boilerplate file
      testFile.writeAsStringSync(boilerplate);

      // Print message
      _messages.add('- ${Colorize(testFile.path).red()}');
      _messages.add('  ${Colorize(implementationFile.path).darkGray()}');
    }
  }

  // ...........................................................................
  Iterable<(File, File)> _findUntestedFiles(
    _Report report,
    Iterable<(File, File)> files,
  ) {
    final result = files.where(
      (e) {
        return !report.containsKey(e.$1.path);
      },
    ).toList();

    return result;
  }

  // ...........................................................................
  void _printUntestedFiles(Iterable<(File, File)> files) {
    for (final tuple in files) {
      final (implementation, test) = tuple;
      _messages.add('- ${Colorize(test.path).red()}');
      _messages.add('  ${Colorize(implementation.path).darkGray()}');
    }
  }

  // ...........................................................................
  Future<int> _test() => _isFlutter ? _testFlutter() : _testDart();

  // ...........................................................................
  Future<int> _testDart() async {
    // Remove the coverage directory
    var coverageDir = Directory('coverage');
    if (coverageDir.existsSync()) {
      coverageDir.deleteSync(recursive: true);
    }

    // Run the Dart coverage command

    var errorLines = <String>{};
    var previousMessagesBelongingToError = <String>[];
    var isError = false;

    var process = await Process.start(
      'dart',
      [
        'test',
        '-r',
        'expanded',
        '--coverage',
        'coverage',
        '--chain-stack-traces',
        '--no-color',
      ],
      // workingDirectory: '/Users/gatzsche/dev/gg_cli_cc',
    );

    // Iterate over stdout and print output using a for loop
    await _processTestOutput(
      process,
      isError,
      previousMessagesBelongingToError,
      errorLines,
    );

    return process.exitCode;
  }

  // ...........................................................................
  Future<void> _processTestOutput(
    Process process,
    bool isError,
    List<String> previousMessagesBelongingToError,
    Set<String> errorLines,
  ) async {
    // Iterate over stdout and print output using a for loop
    await for (var event in process.stdout.transform(utf8.decoder)) {
      isError = isError || event.contains('[E]');
      if (isError) {
        event = _makeErrorLinesInMessageVscodeCompatible(event);
        previousMessagesBelongingToError.add(event);
      }

      final newErrorLines = _extractErrorLines(event);
      if (newErrorLines.isNotEmpty &&
          !errorLines.contains(newErrorLines.first)) {
        // Print error line

        final newErrorLinesString = _addDotSlash(newErrorLines.join(',\n   '));
        _messages.add(Colorize(' - $newErrorLinesString').red().toString());

        // Print messages belonging to this error
        for (var message in previousMessagesBelongingToError) {
          _messages.add(Colorize(message).darkGray().toString());
        }

        isError = false;
      }
      errorLines.addAll(newErrorLines);
    }
  }

  // ...........................................................................
  Future<int> _testFlutter() async {
    int exitCode = 0;

    // Execute flutter tests
    var process = await Process.start(
      'flutter',
      [
        'test',
        '--coverage',
      ],
    );

    var errorLines = <String>{};
    var previousMessagesBelongingToError = <String>[];
    var isError = false;

    // Iterate over stdout and print output using a for loop
    await _processTestOutput(
      process,
      isError,
      previousMessagesBelongingToError,
      errorLines,
    );

    exitCode = await process.exitCode;

    return exitCode;
  }

  // ...........................................................................
  Future<TaskResult> _task() async {
    _isFlutter = _estimateFlutterOrDart();

    // Get implementation files
    final files = _implementationAndTestFiles();

    // Check if test files are missing for implemenation files
    // Directory.current = '/Users/gatzsche/dev/gg_cli_cc';
    final missingTestFiles = _collectMissingTestFiles(files);
    if (missingTestFiles.isNotEmpty) {
      _createMissingTestFiles(missingTestFiles);
      return (1, _messages, _errors);
    }

    // Run Tests
    final error = await _test();

    if (error != 0) {
      return (error, _messages, _errors);
    }

    // Generate coverage reports
    final report = _generateReport();

    // Estimate untested files
    final untestedFiles = _findUntestedFiles(report, files);
    if (untestedFiles.isNotEmpty) {
      _messages.add(
        Colorize('Please add valid tests to the following files:')
            .yellow()
            .toString(),
      );
      _printUntestedFiles(untestedFiles);
      return (1, _messages, _errors);
    }

    var percentage = _calculateCoverage(report);
    _writeLcovReport(report);

    // Check coverage percentage
    if (percentage != 100.0) {
      // Print percentage
      _messages.add(
        Colorize('Coverage not 100%. Untested code:').yellow().toString(),
      );

      // Print missing lines
      final missingLines =
          percentage < 100.0 ? _estimateMissingLines(report) : _MissingLines();

      _printMissingLines(missingLines);

      return (1, _messages, _errors);
    } else {
      _messages.add('✅ Coverage is 100%!');
      return (error, _messages, _errors);
    }
  }
}
