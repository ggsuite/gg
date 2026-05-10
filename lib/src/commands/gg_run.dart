// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:path/path.dart' as p;

/// Command to run a local web server that serves
/// static files from the gg_multi_ui directory.
class GgRun extends Command<void> {
  /// Constructor with required log function and
  /// optional dependency injection for testing.
  ///
  /// [ggLog] is the logging callback.
  /// [serverBinder] is used to bind the HttpServer.
  /// Defaults to [HttpServer.bind].
  /// [uiDirectory] is the directory serving static files.
  /// Defaults to './gg_multi_ui'.
  /// [listenToSigint] determines whether to listen
  /// to SIGINT for graceful shutdown. Defaults to true.
  /// [sigintStream] allows injection of a custom SIGINT stream (for testing).
  /// [exitFn] allows injection of a custom exit function (for testing).
  GgRun({
    required this.ggLog,
    Future<HttpServer> Function(InternetAddress, int)? serverBinder,
    Directory? uiDirectory,
    bool listenToSigint = true,
    Stream<ProcessSignal>? sigintStream,
    void Function(int)? exitFn,
  }) : serverBinder = serverBinder ?? HttpServer.bind,
       uiDirectory = uiDirectory ?? Directory('./gg_multi_ui'),
       _listenToSigint = listenToSigint,
       _sigintStream = sigintStream ?? ProcessSignal.sigint.watch(),
       _exitFn = exitFn ?? exit;

  /// The log function.
  final GgLog ggLog;

  /// Function to bind the HttpServer (for injection in tests).
  final Future<HttpServer> Function(InternetAddress, int) serverBinder;

  /// The directory from which to serve static files.
  final Directory uiDirectory;

  /// Determines whether SIGINT (Ctrl+C) is listened to for graceful shutdown.
  final bool _listenToSigint;

  // Injected stream of SIGINT signals.
  final Stream<ProcessSignal> _sigintStream;

  // Injected exit function.
  final void Function(int) _exitFn;

  @override
  String get name => 'run';

  @override
  String get description =>
      'Starts a local web server that '
      'serves the content of the gg_multi_ui directory. '
      'Press Ctrl+C to stop the server.';

  @override
  Future<void> run() async {
    // Define default port
    const int port = 8084;

    // Log the address of the website.
    ggLog('Starting web server at http://localhost:$port');
    ggLog('Press Ctrl+C to stop the server.');

    // Create HttpServer using the injected serverBinder for easier testing.
    final server = await serverBinder(InternetAddress.loopbackIPv4, port);

    // Setup signal handler for Ctrl+C if enabled.
    if (_listenToSigint) {
      _sigintStream.listen((signal) async {
        ggLog('\nStopping server...');
        await server.close(force: true);
        _exitFn(0);
      });
    }

    // Check if the UI directory exists.
    if (!await uiDirectory.exists()) {
      ggLog(red('Directory gg_multi_ui not found.'));
      await server.close(force: true);
      return;
    }

    // Listen for incoming HTTP requests.
    await for (HttpRequest request in server) {
      await handleRequest(request);
    }
  }

  /// Handles the incoming HTTP request and serves static files.
  Future<void> handleRequest(HttpRequest request) async {
    // Construct the file path based on request.
    String requestedPath = request.uri.path;
    if (requestedPath == '/' || requestedPath.isEmpty) {
      requestedPath = '/index.html'; // default file
    }

    // Get absolute path of the requested file within gg_multi_ui.
    final filePath = uiDirectory.path + requestedPath;
    final file = File(filePath);

    if (await file.exists()) {
      // Determine MIME type based on file extension.
      request.response.headers.contentType = ContentType.parse(
        lookupMimeType(filePath),
      );
      // Serve the file.
      await file.openRead().pipe(request.response);
    } else if (await Directory(filePath).exists()) {
      // If it's a directory, try to serve index.html inside it.
      final indexFile = File(p.join(filePath, 'index.html'));
      if (await indexFile.exists()) {
        request.response.headers.contentType = ContentType.parse(
          lookupMimeType(indexFile.path),
        );
        await indexFile.openRead().pipe(request.response);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('404 Not Found');
        await request.response.close();
      }
    } else {
      // File not found.
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
      await request.response.close();
    }
  }

  /// Returns the MIME type based on file extension.
  String lookupMimeType(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    switch (extension) {
      case '.html':
      case '.htm':
        return 'text/html; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.js':
        return 'application/javascript; charset=utf-8';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.json':
        return 'application/json; charset=utf-8';
      default:
        return 'application/octet-stream';
    }
  }
}
