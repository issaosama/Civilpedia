import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Test-only [HttpOverrides] that satisfies every HTTP request with a tiny
/// transparent 1x1 PNG.
///
/// Used by widget tests that render network-backed image widgets (e.g.
/// `ArticleImage`) without performing real network I/O. This is the extracted
/// known-good implementation originally defined in
/// `test/saved_screen_favorites_test.dart`; do not redesign it.
class PngHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _PngHttpClient();
}

final Uint8List kTransparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _PngHttpClient implements HttpClient {
  @override
  String? userAgent;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  int? maxConnectionsPerHost;
  Future<bool> Function(Uri url, String scheme, String? realm)? authenticate;
  String Function(Uri url)? findProxy;
  bool Function(X509Certificate cert, String host, int port)?
  badCertificateCallback;
  Function(String line)? keyLog;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PngRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _PngRequest(url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _PngRequest(Uri(scheme: 'https', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => get(host, port, path);

  @override
  Future<void> close({bool force = false}) async {}

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClient member: ${invocation.memberName}');
}

class _PngRequest implements HttpClientRequest {
  @override
  final Uri uri;

  _PngRequest(this.uri);

  final _headers = _PngHeaders();

  @override
  int contentLength = 0;

  @override
  bool bufferOutput = true;

  @override
  bool persistentConnection = true;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  Duration? timeout;

  @override
  Future<HttpClientResponse> get done => close();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async => _PngResponse(kTransparentPngBytes);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> add(List<int> data) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClientRequest member: ${invocation.memberName}');
}

class _PngResponse implements HttpClientResponse {
  final Uint8List _bytes;
  _PngResponse(this._bytes);

  final _headers = _PngHeaders();

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  bool get isBroadcast => false;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([_bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClientResponse member: ${invocation.memberName}');
}

class _PngHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];

  @override
  String? value(String name) {
    final values = _map[name.toLowerCase()];
    return values == null || values.isEmpty ? null : values.join(', ');
  }

  @override
  void remove(String name, Object value) {
    final list = _map[name.toLowerCase()];
    if (list != null) list.remove(value.toString());
  }

  @override
  void removeAll(String name) => _map.remove(name.toLowerCase());

  @override
  void clear() => _map.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpHeaders member: ${invocation.memberName}');
}
