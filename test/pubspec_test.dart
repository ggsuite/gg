import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('pubspec.yaml uses fixed versions (no ^ or ~)', () {
    // gg is an end product: Therefore versions are set to fixed
    // versions.
    // Use "dart pub upgrade --major-versions --tighten" to update versions to
    // latest state.
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue, reason: 'pubspec.yaml not found');

    final lines = pubspec.readAsLinesSync();
    final offenders = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final line = raw.split('#').first;
      if (line.contains('^') ||
          RegExp(r'(^|\s):\s*~').hasMatch(line) ||
          RegExp(r'version:\s*~').hasMatch(line) ||
          line.trimLeft().startsWith('~')) {
        offenders.add('Line ${i + 1}: $raw');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: [
        'pubspec.yaml must use fixed versions (no "^" or "~"). ',
        'gg is an end product: Therefore versions are set to fixed '
            'versions.',
        'Use "dart pub upgrade --major-versions --tighten"',
        ' to update versions to the latest state.',
        '',
        'Offending lines:',
        ...offenders,
      ].join('\n'),
    );
  }, skip: true);
}
