// @license
// Copyright (c) 2019 - 2025 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:gg/src/commands/gg_run.dart';
import 'package:path/path.dart' as p;

void main() {
  group('GgRun.handleRequest', () {
    late Directory tempUiDir;
    late List<String> logMessages;
    late GgRun ggRun;

    setUp(() async {
      // Create a temporary directory to act as the gg_multi_ui directory
      tempUiDir = await Directory.systemTemp.createTemp('gg_multi_ui_test');
      logMessages = [];
      // Create an instance of GgRun with injected uiDirectory
      ggRun = GgRun(
        ggLog: (msg) => logMessages.add(msg),
        uiDirectory: tempUiDir,
      );
    });

    tearDown(() async {
      if (await tempUiDir.exists()) {
        await tempUiDir.delete(recursive: true);
      }
    });

    test('serves index.html for root request', () async {
      // Create index.html in tempUiDir with sample content
      final indexFile = File(p.join(tempUiDir.path, 'index.html'));
      const content = '<html>Hello World</html>';
      await indexFile.writeAsString(content);

      // Create fake request for '/'
      final fakeResponse = FakeHttpResponse();
      final fakeRequest = FakeHttpRequest(
        uri: Uri.parse('/'),
        response: fakeResponse,
      );

      await ggRun.handleRequest(fakeRequest);

      // Verify that the response header has correct MIME type
      expect(
        fakeResponse.headers['content-type']?.first,
        'text/html; charset=utf-8',
      );
      // Verify that the response body contains the file content
      expect(utf8.decode(fakeResponse.bodyBytes), content);
    });

    test('serves file with different extension (CSS)', () async {
      // Create file.css in tempUiDir
      final cssFile = File(p.join(tempUiDir.path, 'styles.css'));
      const content = 'body { background: #fff; }';
      await cssFile.writeAsString(content);

      // Create fake request for '/styles.css'
      final fakeResponse = FakeHttpResponse();
      final fakeRequest = FakeHttpRequest(
        uri: Uri.parse('/styles.css'),
        response: fakeResponse,
      );

      await ggRun.handleRequest(fakeRequest);

      // Validate MIME type for CSS
      expect(
        fakeResponse.headers['content-type']?.first,
        'text/css; charset=utf-8',
      );
      expect(utf8.decode(fakeResponse.bodyBytes), content);
    });

    test(
      'serves index.html from a subdirectory when directory is requested',
      () async {
        // Create a subdirectory inside tempUiDir
        final subDir = Directory(p.join(tempUiDir.path, 'subdir'));
        await subDir.create();
        // Create an index.html inside the subdirectory
        final indexFile = File(p.join(subDir.path, 'index.html'));
        const content = '<html>Subdirectory Index</html>';
        await indexFile.writeAsString(content);

        // Create fake request for '/subdir'
        final fakeResponse = FakeHttpResponse();
        final fakeRequest = FakeHttpRequest(
          uri: Uri.parse('/subdir'),
          response: fakeResponse,
        );

        await ggRun.handleRequest(fakeRequest);

        // Check that the MIME type is set to HTML
        expect(
          fakeResponse.headers['content-type']?.first,
          'text/html; charset=utf-8',
        );
        expect(utf8.decode(fakeResponse.bodyBytes), content);
      },
    );

    test('returns 404 for non-existent file', () async {
      // Do not create the requested file
      final fakeResponse = FakeHttpResponse();
      final fakeRequest = FakeHttpRequest(
        uri: Uri.parse('/nonexistent.html'),
        response: fakeResponse,
      );

      await ggRun.handleRequest(fakeRequest);

      // Verify that status code is set
      // to 404 and response contains error message
      expect(fakeResponse.statusCode, HttpStatus.notFound);
      expect(utf8.decode(fakeResponse.bodyBytes), '404 Not Found');
      expect(fakeResponse.closed, true);
    });

    test(
      'returns 404 when directory exists but index.html is missing',
      () async {
        // Create a subdirectory without an index.html
        final subDir = Directory(p.join(tempUiDir.path, 'emptydir'));
        await subDir.create();

        final fakeResponse = FakeHttpResponse();
        final fakeRequest = FakeHttpRequest(
          uri: Uri.parse('/emptydir'),
          response: fakeResponse,
        );

        await ggRun.handleRequest(fakeRequest);

        expect(fakeResponse.statusCode, HttpStatus.notFound);
        expect(utf8.decode(fakeResponse.bodyBytes), '404 Not Found');
        expect(fakeResponse.closed, true);
      },
    );
  });

  group('GgRun.lookupMimeType', () {
    late GgRun ggRun;

    setUp(() {
      ggRun = GgRun(ggLog: print);
    });

    test('returns correct MIME type for .html', () {
      final mime = ggRun.lookupMimeType('dummy/index.html');
      expect(mime, 'text/html; charset=utf-8');
    });

    test('returns correct MIME type for .css', () {
      final mime = ggRun.lookupMimeType('style.css');
      expect(mime, 'text/css; charset=utf-8');
    });

    test('returns correct MIME type for .js', () {
      final mime = ggRun.lookupMimeType('script.js');
      expect(mime, 'application/javascript; charset=utf-8');
    });

    test('returns correct MIME type for unknown extension', () {
      final mime = ggRun.lookupMimeType('file.unknown');
      expect(mime, 'application/octet-stream');
    });
  });

  // Additional tests to increase coverage for the run() method
  group('GgRun.run', () {
    test('logs error when uiDirectory does not exist', () async {
      // Create a non-existent directory path
      final nonExistentDir = Directory(
        p.join(Directory.systemTemp.path, 'nonexistent_gg_multi_ui'),
      );
      if (await nonExistentDir.exists()) {
        await nonExistentDir.delete(recursive: true);
      }

      // Create a FakeHttpServer with an empty stream
      final fakeServer = FakeHttpServer(const Stream<HttpRequest>.empty());

      // Capture log messages
      final logMessages = <String>[];

      // Provide a serverBinder that returns our fake server
      Future<HttpServer> fakeBinder(InternetAddress address, int port) async {
        return fakeServer;
      }

      final ggRun = GgRun(
        ggLog: (msg) => logMessages.add(msg),
        serverBinder: fakeBinder,
        uiDirectory: nonExistentDir,
      );

      // Run the server. It should detect that uiDirectory does not exist,
      // log an error, close the server, and return.
      await ggRun.run();

      // Check that the log contains the directory not found message
      expect(
        logMessages.any(
          (msg) => msg.contains('Directory gg_multi_ui not found.'),
        ),
        isTrue,
      );
    });

    test('starts web server when uiDirectory exists', () async {
      // Create a temporary directory to act as the gg_multi_ui directory
      final tempUiDir = await Directory.systemTemp.createTemp(
        'gg_multi_ui_existing',
      );

      // Create a FakeHttpServer with an
      // empty stream to simulate no incoming requests
      final fakeServer = FakeHttpServer(const Stream<HttpRequest>.empty());

      // Capture log messages
      final logMessages = <String>[];

      // Provide a serverBinder that returns our fake server
      Future<HttpServer> fakeBinder(InternetAddress address, int port) async {
        return fakeServer;
      }

      final ggRun = GgRun(
        ggLog: (msg) => logMessages.add(msg),
        serverBinder: fakeBinder,
        uiDirectory: tempUiDir,
      );

      // Run the server. Since the uiDirectory
      // exists and the fake server stream is empty,
      // run() should log the starting messages and then complete.
      await ggRun.run();

      // Verify that the log contains startup messages
      expect(
        logMessages.any(
          (msg) => msg.contains('Starting web server at http://localhost:8084'),
        ),
        isTrue,
      );
      expect(
        logMessages.any(
          (msg) => msg.contains('Press Ctrl+C to stop the server.'),
        ),
        isTrue,
      );

      // Cleanup
      await tempUiDir.delete(recursive: true);
    });

    test('processes incoming request from fake server', () async {
      // Create a temporary directory to act as the gg_multi_ui directory
      final tempUiDir = await Directory.systemTemp.createTemp(
        'gg_multi_ui_test',
      );
      // Create an index.html in tempUiDir with sample content
      final indexFile = File(p.join(tempUiDir.path, 'index.html'));
      const fileContent = '<html>Test Page</html>';
      await indexFile.writeAsString(fileContent);

      // Create a StreamController to simulate HttpRequest stream
      final controller = StreamController<HttpRequest>();
      final fakeServer = FakeHttpServer(controller.stream);

      // Capture log messages
      final logMessages = <String>[];

      // Provide a serverBinder that returns our fake server
      Future<HttpServer> fakeBinder(InternetAddress address, int port) async {
        return fakeServer;
      }

      // Create GgRun with SIGINT handling disabled for testing
      final ggRun = GgRun(
        ggLog: (msg) => logMessages.add(msg),
        serverBinder: fakeBinder,
        uiDirectory: tempUiDir,
        listenToSigint: false,
      );

      // Start ggRun.run() in a separate future
      final runFuture = ggRun.run();

      // Create a fake request for '/'
      final fakeResponse = FakeHttpResponse();
      final fakeRequest = FakeHttpRequest(
        uri: Uri.parse('/'),
        response: fakeResponse,
      );

      // Add the fake request to the stream and close the controller
      controller.add(fakeRequest);
      await controller.close();

      // Wait for run() to complete
      await runFuture;

      // Verify that the content of index.html was served
      expect(utf8.decode(fakeResponse.bodyBytes), fileContent);

      // Cleanup temporary directory
      await tempUiDir.delete(recursive: true);
    });

    test('handles SIGINT signal', () async {
      // Create a temporary directory to act as the gg_multi_ui directory
      final tempUiDir = await Directory.systemTemp.createTemp(
        'gg_multi_ui_sigint',
      );

      // Create a StreamController to simulate SIGINT signal
      final sigintController = StreamController<ProcessSignal>();
      bool exitCalled = false;
      void fakeExit(int code) {
        exitCalled = true;
      }

      // Use a fake server with empty request stream
      final fakeServer = FakeHttpServer(const Stream<HttpRequest>.empty());

      final logMessages = <String>[];

      final ggRun = GgRun(
        ggLog: (msg) => logMessages.add(msg),
        serverBinder: (addr, port) async => fakeServer,
        uiDirectory: tempUiDir,
        listenToSigint: true,
        sigintStream: sigintController.stream,
        exitFn: fakeExit,
      );

      // Start ggRun.run() in background
      final runFuture = ggRun.run();

      // Emit SIGINT signal
      sigintController.add(ProcessSignal.sigint);
      await sigintController.close();
      await runFuture;

      // Verify that the log contains the stopping message and exit was called
      expect(logMessages.any((msg) => msg.contains('Stopping server')), isTrue);
      expect(exitCalled, isTrue);
      await tempUiDir.delete(recursive: true);
    });
  });

  // tests to cover default constructor values for GgRun
  group('GgRun constructor defaults', () {
    test('defaults uiDirectory to "./gg_multi_ui"', () {
      final ggRun = GgRun(ggLog: print);
      expect(ggRun.uiDirectory.path, './gg_multi_ui');
    });

    test('defaults serverBinder to HttpServer.bind', () async {
      final ggRun = GgRun(ggLog: print);
      // Test that serverBinder returns a
      // valid HttpServer when binding to an available port.
      final server = await ggRun.serverBinder(InternetAddress.loopbackIPv4, 0);
      expect(server, isA<HttpServer>());
      await server.close();
    });
  });

  group('GgRun properties', () {
    test('returns name "run"', () {
      final ggRun = GgRun(ggLog: print);
      expect(ggRun.name, equals('run'));
    });

    test('returns correct description', () {
      final ggRun = GgRun(ggLog: print);
      expect(ggRun.description, contains('Starts a local web server'));
    });
  });
}

// #############################################################################
// Fake classes for testing

// Fake implementation of HttpHeaders to capture header changes.
class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  // Internal variable to store contentType
  ContentType? _contentType;

  /// Setter for contentType
  @override
  set contentType(ContentType? value) {
    _contentType = value;
    _headers['content-type'] = [value.toString()];
  }

  /// Getter for contentType
  @override
  ContentType? get contentType => _contentType;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    // Set header value
    _headers[name] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _headers[name];

  // Other members are not needed for our tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake HttpResponse to capture written data and headers.
class FakeHttpResponse implements HttpResponse {
  FakeHttpResponse() : headers = FakeHttpHeaders();

  @override
  final FakeHttpHeaders headers;

  final List<int> bodyBytes = [];
  @override
  int statusCode = 200;
  bool closed = false;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    // Add bytes from stream to bodyBytes
    await for (var chunk in stream) {
      bodyBytes.addAll(chunk);
    }
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  void write(Object? obj) {
    // Write string to bodyBytes
    final encoded = utf8.encode(obj.toString());
    bodyBytes.addAll(encoded);
  }

  // Implement pipe as a simple call to addStream.
  Future<void> pipe(Stream<List<int>> stream) => addStream(stream);

  // Other members are not needed for our tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake HttpRequest to use in tests.
class FakeHttpRequest implements HttpRequest {
  FakeHttpRequest({required this.uri, required this.response});

  @override
  final Uri uri;

  @override
  final FakeHttpResponse response;

  // Other members are not needed for our tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake HttpServer to simulate a server with controllable request stream.
class FakeHttpServer implements HttpServer {
  final Stream<HttpRequest> _stream;
  bool closed = false;

  FakeHttpServer(this._stream);

  @override
  StreamSubscription<HttpRequest> listen(
    void Function(HttpRequest event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<void> close({bool force = false}) async {
    closed = true;
  }

  // Other members can use noSuchMethod.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
