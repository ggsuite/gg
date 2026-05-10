// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:test/test.dart';

import '../../bin/gg.dart';

void main() {
  late Directory dRoot;
  late Directory d0;
  final messages = <String>[];
  final ggLog = messages.add;

  // ...........................................................................
  Future<void> initDartPackages() async {
    // Create a pubspec.yaml file in each directory, except dir2
    await File('${d0.path}/pubspec.yaml').writeAsString('name: dir0');

    // Create a textfile in each directory
    await File('${d0.path}/file0.txt').writeAsString('file0');
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();

    dRoot = await Directory.systemTemp.createTemp('gg_test');
    d0 = await Directory('${dRoot.path}/dir0').create();
    await initDartPackages();
  });

  tearDown(() async {
    await dRoot.delete(recursive: true);
  });

  group('main(args)', () {
    group('should runGg', () {
      group('- edge cases', () {
        group('should catch and print errors', () {
          test('- no arguments', () async {
            await runGg(args: [], ggLog: ggLog);
            expect(messages[0], contains('Missing subcommand for'));
          });

          test('- unknown argument', () async {
            await runGg(args: [dRoot.path, '--unknown'], ggLog: ggLog);
            expect(
              messages[0],
              contains('Could not find an option named --unknown'),
            );
          });
        });
      });
    });
  });
}
