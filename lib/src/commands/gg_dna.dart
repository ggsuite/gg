#!/usr/bin/env dart

// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_one/gg_one.dart'
    show GgPrompts, GgPromptsUnsupportedError, HasTerminal, defaultHasTerminal;
import 'package:helix/helix.dart' as helix;

/// Answers the questions of helix through the prompts of the gg suite —
/// the same menus `gg do publish` draws, and in an embedded gg whatever
/// the embedder assigned to [GgPrompts.current].
///
/// Throws [helix.PromptUnavailableException] when there is nobody to ask
/// (see [_ask]), so helix falls back as it does for its own terminal
/// prompts. [hasTerminal] and [ownPrompts] replace stdin and the prompts
/// gg draws itself in tests.
Future<int> helixSelectPrompt({
  required String prompt,
  required List<String> options,
  HasTerminal hasTerminal = defaultHasTerminal,
  GgPrompts? ownPrompts,
}) => _ask(
  (prompts) => prompts.select(prompt: prompt, options: options),
  hasTerminal: hasTerminal,
  ownPrompts: ownPrompts,
);

/// Asks helix's text questions — the variables a layer marks
/// `mustOverride` — through the input prompt of the gg suite. An empty
/// answer takes [defaultValue] and is asked again when there is none:
/// helix expects a value, never an empty string.
///
/// Throws [helix.PromptUnavailableException] when there is nobody to ask,
/// like [helixSelectPrompt].
Future<String> helixTextPrompt({
  required String prompt,
  String? defaultValue,
  HasTerminal hasTerminal = defaultHasTerminal,
  GgPrompts? ownPrompts,
}) async {
  while (true) {
    final answer = (await _ask(
      (prompts) => prompts.input(prompt: prompt, defaultValue: defaultValue),
      hasTerminal: hasTerminal,
      ownPrompts: ownPrompts,
    )).trim();
    if (answer.isNotEmpty) return answer;
    if (defaultValue != null) return defaultValue;
  }
}

/// Asks [question] with [GgPrompts.current] and turns "nobody to ask" into
/// the [helix.PromptUnavailableException] helix expects:
///
/// - a platform that cannot draw prompts (Wasm without an embedder),
/// - gg's own prompts — [ownPrompts], by default
///   [GgPrompts.defaultPrompts] — on a stdin that is no terminal: they
///   would wait forever in CI, in a pipe or behind a null device,
/// - gg's own prompts failing to read the terminal: Git Bash on Windows
///   reports a terminal for redirected input, and reading it then fails.
///
/// An embedder that assigned [GgPrompts.current] answers without a
/// terminal: it is never checked, and its errors are its own.
Future<T> _ask<T>(
  Future<T> Function(GgPrompts prompts) question, {
  required HasTerminal hasTerminal,
  required GgPrompts? ownPrompts,
}) async {
  final prompts = GgPrompts.current;
  final isOwn = identical(prompts, ownPrompts ?? GgPrompts.defaultPrompts);
  if (isOwn) _ensureTerminal(hasTerminal);
  try {
    return await question(prompts);
  } on GgPromptsUnsupportedError catch (e) {
    throw helix.PromptUnavailableException('$e');
  } on Object catch (e) {
    if (!isOwn) rethrow;
    throw helix.PromptUnavailableException('the terminal cannot be read: $e');
  }
}

/// Throws [helix.PromptUnavailableException] unless [hasTerminal] says
/// stdin is a terminal.
void _ensureTerminal(HasTerminal hasTerminal) {
  final bool isTerminal;
  try {
    isTerminal = hasTerminal();
  } on Object {
    // A platform without stdin (Wasm) has nobody to ask either.
    throw const helix.PromptUnavailableException('stdin cannot be read');
  }
  if (!isTerminal) {
    throw const helix.PromptUnavailableException('stdin is not a terminal');
  }
}

/// Command that exposes all helix subcommands under the `dna` namespace.
class GgDna extends Command<void> {
  /// Create the command and register all helix subcommands.
  GgDna({required this.ggLog}) {
    helix.Helix(
      ggLog: ggLog,
      selectPrompt: helixSelectPrompt,
      textPrompt: helixTextPrompt,
    ).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'dna';

  @override
  String get description => 'Manage the DNA of a repo';
}
