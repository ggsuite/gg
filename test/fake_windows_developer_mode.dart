// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_is_github/gg_is_github.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

/// A platform reporting a fixed operating system.
class FakePlatform extends GgPlatformDelegate {
  const FakePlatform([this.operatingSystem = 'windows']);

  @override
  final String operatingSystem;
}

/// Answers every process with [exitCode] and [stdout], or throws [error],
/// and records the calls in [calls].
class FakeReg extends GgProcessDelegate {
  FakeReg({this.exitCode = 0, this.stdout = '', this.error});

  /// What `reg query` prints for the developer mode value set to [value].
  FakeReg.value(String value)
    : this(
        stdout:
            '\r\n$_key\r\n'
            '    AllowDevelopmentWithoutDevLicense    REG_DWORD    $value'
            '\r\n\r\n',
      );

  static const _key =
      r'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock';

  final int exitCode;
  final String stdout;
  final Object? error;
  final calls = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) async {
    calls.add([executable, ...arguments]);
    if (error != null) throw error!;
    return ProcessResult(0, exitCode, stdout, '');
  }
}

/// Lets the current test run on [platform] outside GitHub Actions, with
/// [reg] answering the registry query.
void fakeWindows(FakeReg reg, {FakePlatform platform = const FakePlatform()}) {
  GgPlatformDelegate.current = platform;
  GgProcessDelegate.current = reg;
  testIsGitHub = false;
  addTearDown(() {
    GgPlatformDelegate.current = null;
    GgProcessDelegate.current = null;
    testIsGitHub = null;
  });
}
