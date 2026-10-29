// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_is_github/gg_is_github.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';

import 'host/gg_host.dart';
import 'project_detector.dart';

/// Returns false and logs how to enable the Windows developer mode when gg
/// runs on Windows with the developer mode disabled.
///
/// gg creates symbolic links, which Windows only allows a normal user with
/// the developer mode enabled. Stopping up front with a hint beats failing
/// somewhere in the middle of a command.
///
/// Passes off Windows, under an installed [GgHost] (the host creates the
/// links), on GitHub Actions (the runners are elevated), for [isUsageOnly]
/// calls and when the registry cannot be read — a broken check must not
/// block gg.
Future<bool> checkWindowsDeveloperMode({
  required List<String> args,
  required GgLog ggLog,
}) async {
  if (!ggPlatform.isWindows ||
      GgHost.installed != null ||
      isGitHub ||
      isUsageOnly(args)) {
    return true;
  }

  switch (await _isDeveloperModeEnabled()) {
    case true:
      return true;
    case null:
      ggLog(
        cWarn(
          'Could not check whether the Windows developer mode is enabled. '
          'gg needs it to create symbolic links.',
        ),
      );
      return true;
    case false:
      // Concatenated rather than nested: a cCmd inside a cError resets the
      // red and the rest of the sentence loses it.
      ggLog(
        '${cError(_disabledHint)}'
        '${cCmd('start ms-settings:developers')}'
        '${cError('), then run gg again.')}',
      );
      return false;
  }
}

const _disabledHint =
    'gg needs the Windows developer mode, it creates symbolic links.\n'
    'Enable it: Settings → System → For developers → Developer Mode\n'
    '(or run: ';

/// Reads the developer mode from the registry: null when it cannot be read.
Future<bool?> _isDeveloperModeEnabled() async {
  final ProcessResult result;
  try {
    result = await ggRunProcess('reg', [
      'query',
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock',
      '/v',
      'AllowDevelopmentWithoutDevLicense',
    ]);
  } catch (_) {
    return null;
  }

  // reg fails when the key or the value does not exist, which is the case
  // on a Windows where the developer mode was never enabled.
  if (result.exitCode != 0) return false;

  final match = _dword.firstMatch(result.stdout.toString());
  if (match == null) return null;
  return int.parse(match.group(1)!, radix: 16) != 0;
}

final _dword = RegExp(r'REG_DWORD\s+0x([0-9a-f]+)', caseSensitive: false);
