// QA-only synthetic backend and configuration for the full App retry harness
// (scripts/qa/run_full_app_retry_android.py). Nothing here is a real account
// value: every key is a synthetic string and every fetchable endpoint is the
// in-process loopback server. No actual config/*.json file is ever read.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// The version the runner gives the generated QA app (pubspec 0.0.1+1).
const qaAppVersion = '0.0.1';

/// Update URL in the synthetic version row. It is never opened.
const qaUpdateUrl = 'https://example.invalid/picnic-qa-update';

/// One synthetic response.
class LoopbackReply {
  const LoopbackReply(this.status, this.body);

  final int status;
  final Object body;
}

/// The bounded set of requests the App startup is known to make with no
/// session. Anything else gets no answer here and is diagnosed.
LoopbackReply? resolveLoopbackRoute(String method, String path) {
  if (path.startsWith('/auth/v1/')) {
    // No session is ever granted or refreshed.
    return const LoopbackReply(401, {
      'code': 401,
      'error_code': 'no_authorization',
      'msg': 'qa-loopback: no session',
    });
  }
  if (method == 'GET' && path == '/rest/v1/version') {
    // PostgREST .single() asks for one object, not a list.
    return const LoopbackReply(200, {
      'id': 1,
      'android': {
        'version': qaAppVersion,
        'force_version': qaAppVersion,
        'url': qaUpdateUrl,
      },
      'ios': {
        'version': qaAppVersion,
        'force_version': qaAppVersion,
        'url': qaUpdateUrl,
      },
      'macos': <String, Object>{},
      'windows': <String, Object>{},
      'linux': <String, Object>{},
    });
  }
  if (method == 'GET' && path == '/rest/v1/products') {
    return const LoopbackReply(200, <Object>[]);
  }
  if (method == 'POST' && path == '/functions/v1/track-country') {
    return const LoopbackReply(200, {'ip_hash': 'unknown'});
  }
  if (method == 'POST' && RegExp(r'^/api/\d+/envelope/$').hasMatch(path)) {
    // Sentry ingest for the loopback DSN. The body is drained, never kept.
    return const LoopbackReply(200, <String, Object>{});
  }
  return null;
}

/// HTTP server on 127.0.0.1 with an OS-assigned port.
///
/// It keeps only `METHOD /path` for each request: no query, header or body.
class LoopbackBackend {
  LoopbackBackend._(this._server, this._log);

  final HttpServer _server;
  final void Function(String line) _log;
  final List<String> requests = <String>[];
  final List<String> unexpected = <String>[];

  static Future<LoopbackBackend> start(
      {void Function(String line)? log}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final backend = LoopbackBackend._(server, log ?? (_) {});
    server.listen(
      (request) => unawaited(backend._handle(request)),
      onError: (Object error) => backend._log('QA_LOOPBACK_SERVER_ERROR '
          '${error.runtimeType}'),
    );
    return backend;
  }

  Uri get base => Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: _server.port,
      );

  String get sentryDsn =>
      'http://qa-synthetic-public-key@${base.host}:${base.port}/1';

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final line = '${request.method} ${request.uri.path}';
    requests.add(line);
    try {
      await request.drain<void>();
    } catch (_) {
      // A client that went away has nothing left to answer.
    }
    var reply = resolveLoopbackRoute(request.method, request.uri.path);
    if (reply == null) {
      unexpected.add(line);
      reply = const LoopbackReply(404, {
        'code': 'QA_UNANTICIPATED',
        'message': 'qa-loopback: unanticipated route',
      });
    }
    _log('QA_LOOPBACK $line -> ${reply.status}');
    try {
      request.response
        ..statusCode = reply.status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reply.body));
      await request.response.close();
    } catch (_) {
      // The client closed the connection first.
    }
  }
}

Map<String, dynamic> _config({
  required String base,
  required String anonKey,
  required String sentryDsn,
  required String label,
  required String inappPrefix,
}) =>
    <String, dynamic>{
      'supabase': {
        'url': base,
        'anon_key': anonKey,
        'storage': {'url': base, 'anon_key': anonKey},
      },
      'auth': {
        'apple': {
          'client_id': 'io.picnic.qa.$label.apple',
          'redirect_uri': 'https://example.invalid/qa-$label/apple',
        },
        'google': {
          'client_id': 'qa-synthetic-$label-google-client',
          'server_client_id': 'qa-synthetic-$label-google-server-client',
        },
        'kakao': {
          'native_app_key': 'qa-synthetic-$label-kakao-native',
          'javascript_key': 'qa-synthetic-$label-kakao-js',
        },
      },
      'sentry': {
        // Events are filtered before sending; the DSN is loopback in any case.
        'enable': false,
        'app_dsn': sentryDsn,
        'web_dsn': sentryDsn,
        'sample_rates': {
          'trace': 0.0,
          'profile': 0.0,
          'session': 0.0,
          'error': 1.0,
        },
      },
      'storage': {
        'cdn_url': '$base/qa-cdn',
        'aws': {
          'access_key_id': 'qa-synthetic-$label-access-key',
          'secret_access_key': 'qa-synthetic-$label-secret',
          'region': 'qa-synthetic-region',
          's3_bucket': 'qa-synthetic-$label-bucket',
          's3_bucket_url': '$base/qa-bucket',
        },
      },
      'api_keys': {
        'youtube': 'qa-synthetic-$label-youtube',
        'deepl': 'qa-synthetic-$label-deepl',
        'branch': 'qa-synthetic-$label-branch',
      },
      'app': {
        'web_domain': base,
        'download_link': 'https://example.invalid/qa-$label/download',
        'app_link_prefix': 'https://example.invalid/qa-$label/link',
        'inapp_appname_prefix': inappPrefix,
      },
      'theme': {
        'colors': {
          'primary': '0xFF9374FF',
          'secondary': '0xFF83FBC8',
          'sub': '0xFFCDFB5D',
          'point': '0xFFFFA9BD',
          'point_900': '0xFFEB4A71',
        },
      },
      'ads': {
        'tapjoy': {
          'ios_sdk_key': 'qa-synthetic-$label-tapjoy-ios',
          'android_sdk_key': 'qa-synthetic-$label-tapjoy-android',
        },
        'pangle': {
          'ios_app_id': 'qa-synthetic-$label-pangle-ios',
          'ios_rewarded_video_id': 'qa-synthetic-$label-pangle-ios-rewarded',
          'android_app_id': 'qa-synthetic-$label-pangle-android',
          'android_rewarded_video_id':
              'qa-synthetic-$label-pangle-android-rewarded',
        },
        'pincrux': {
          'android_app_key': 'qa-synthetic-$label-pincrux-android',
          'ios_app_key': 'qa-synthetic-$label-pincrux-ios',
        },
        'admob': {
          // Google's published sample rewarded ad units, never production units.
          'ios_rewarded_video_id': 'ca-app-pub-3940256099942544/1712485313',
          'android_rewarded_video_id': 'ca-app-pub-3940256099942544/5224354917',
        },
      },
      'crowdin': {'distribution_hash': 'qa-synthetic-$label-crowdin'},
    };

/// The synthetic `config/local.json`: Supabase, storage, CDN and Sentry all
/// point at [base] (the loopback server), as the local policy requires.
Map<String, dynamic> syntheticLocalConfig(
  Uri base, {
  required String sentryDsn,
}) =>
    _config(
      base: base.toString(),
      anonKey: 'qa-synthetic-local-anon-key',
      sentryDsn: sentryDsn,
      label: 'local',
      inappPrefix: '',
    );

/// The synthetic `config/prod.json`. The local policy only compares it with
/// the local values, so it must differ from them; nothing connects to it.
/// Its endpoints are a closed loopback port, never a production host.
Map<String, dynamic> syntheticProductionConfig() => _config(
      base: 'http://127.0.0.1:9',
      anonKey: 'qa-synthetic-production-anon-key',
      sentryDsn: 'http://qa-synthetic-production-key@127.0.0.1:9/1',
      label: 'production',
      inappPrefix: 'qa_synthetic_production_',
    );

/// Answers the `flutter/assets` channel for exactly `config/local.json` and
/// `config/prod.json` with the synthetic configs. Any other `config/` asset
/// is refused (not found); every other asset is forwarded unchanged.
class SyntheticConfigAssets {
  SyntheticConfigAssets({
    required Map<String, dynamic> local,
    required Map<String, dynamic> production,
  }) : _files = {
          'config/local.json':
              Uint8List.fromList(utf8.encode(jsonEncode(local))),
          'config/prod.json': Uint8List.fromList(
            utf8.encode(jsonEncode(production)),
          ),
        };

  final Map<String, Uint8List> _files;
  final Map<String, int> served = <String, int>{};
  final List<String> refused = <String>[];

  Future<ByteData?> handle(
    ByteData? message,
    Future<ByteData?>? Function(ByteData? message) forward,
  ) async {
    if (message == null) return forward(message);
    final key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    final bytes = _files[key];
    if (bytes != null) {
      served[key] = (served[key] ?? 0) + 1;
      return ByteData.sublistView(bytes);
    }
    if (key.startsWith('config/')) {
      refused.add(key);
      return null;
    }
    return forward(message);
  }
}
