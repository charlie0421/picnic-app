// QA-only synthetic vote list backend for the iOS notification delivery QA
// app (scripts/qa/run_notification_delivery_ios.py). Nothing here is a real
// account value: every key is a synthetic string and every fetchable endpoint
// is the in-process loopback server on 127.0.0.1. No config/*.json file is
// read.
//
// The server answers exactly one route: GET /rest/v1/vote with the PostgREST
// filters that the product AsyncVoteList provider sends for the active, end
// and upcoming statuses, with or without one `areas` filter. Any other path
// or method gets 404 and is recorded as unexpected. An unknown filter
// combination gets 400, so a changed product query cannot pass silently.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Synthetic anon key. It is not a credential and names no project.
const qaSyntheticAnonKey = 'qa-synthetic-notification-delivery-anon-key';

/// One synthetic vote. [phase] is 'active', 'end' or 'upcoming'.
class _SyntheticVote {
  const _SyntheticVote(
    this.id,
    this.area,
    this.phase,
    this.titleEn,
    this.titleKo, {
    required this.visibleDays,
    required this.startDays,
    required this.stopDays,
  });

  final int id;
  final String area;
  final String phase;
  final String titleEn;
  final String titleKo;
  final int visibleDays;
  final int startDays;
  final int stopDays;
}

/// Fixed fixtures, relative to the request time. The ids are QA-only.
const List<_SyntheticVote> _votes = [
  _SyntheticVote(910001, 'kpop', 'active', 'QA Active PICNIC', 'QA 진행 PICNIC',
      visibleDays: -2, startDays: -1, stopDays: 3),
  _SyntheticVote(
      910002, 'musical', 'active', 'QA Active MUSICAL', 'QA 진행 MUSICAL',
      visibleDays: -2, startDays: -1, stopDays: 6),
  _SyntheticVote(910003, 'kpop', 'end', 'QA Ended PICNIC', 'QA 종료 PICNIC',
      visibleDays: -12, startDays: -10, stopDays: -2),
  _SyntheticVote(910004, 'musical', 'end', 'QA Ended MUSICAL', 'QA 종료 MUSICAL',
      visibleDays: -12, startDays: -10, stopDays: -1),
  _SyntheticVote(
      910005, 'kpop', 'upcoming', 'QA Upcoming PICNIC', 'QA 예정 PICNIC',
      visibleDays: -1, startDays: 2, stopDays: 9),
];

/// The result of one request.
class VoteListReply {
  const VoteListReply(this.status, this.body, {this.area, this.voteStatus});

  final int status;
  final Object body;

  /// 'all' or the single requested area; null when the request was refused.
  final String? area;

  /// 'active', 'end' or 'upcoming'; null when the request was refused.
  final String? voteStatus;
}

const _notFound = VoteListReply(404, {
  'code': 'QA_UNANTICIPATED',
  'message': 'qa-loopback: unanticipated route',
});

VoteListReply _refused(String reason) => VoteListReply(400, {
      'code': 'QA_UNSUPPORTED_FILTER',
      'message': 'qa-loopback: $reason',
    });

/// Status filters exactly as AsyncVoteList sends them (vote_list_provider).
const Map<String, Map<String, String>> _statusFilters = {
  'active': {
    'visible_at': 'lt.now()',
    'start_at': 'lt.now()',
    'stop_at': 'gt.now()',
  },
  'end': {'stop_at': 'lt.now()'},
  'upcoming': {'visible_at': 'lt.now()', 'start_at': 'gt.now()'},
};

const _timeKeys = {'visible_at', 'start_at', 'stop_at'};

/// Query keys that do not change which rows are selected here.
const _ignoredKeys = {
  'select',
  'deleted_at',
  'vote_item.deleted_at',
  'vote_item.order',
  'vote_item.limit',
};

String _iso(DateTime value) => value.toUtc().toIso8601String();

Map<String, dynamic> _row(_SyntheticVote vote, DateTime now) {
  DateTime at(int days) => now.add(Duration(days: days));
  Map<String, dynamic> item(int suffix, int total, String artist) => {
        'id': vote.id * 10 + suffix,
        'vote_id': vote.id,
        'vote_total': total,
        'artist': {
          'id': 9100 + suffix,
          'name': {'en': 'QA Artist $artist', 'ko': 'QA 아티스트 $artist'},
          'image': null,
        },
        'artist_group': null,
      };
  return {
    'id': vote.id,
    'title': {'en': vote.titleEn, 'ko': vote.titleKo},
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'created_at': _iso(at(-30)),
    'start_at': _iso(at(vote.startDays)),
    'stop_at': _iso(at(vote.stopDays)),
    'visible_at': _iso(at(vote.visibleDays)),
    'vote_category': 'birthday',
    'is_partnership': false,
    'partner': null,
    'reward': <Object>[],
    // vote_total descending, as the product embed order asks.
    'vote_item': [item(2, 500, 'B'), item(1, 100, 'A')],
  };
}

/// Answers one request. Pure: the same input gives the same reply.
VoteListReply resolveVoteListRequest(
  String method,
  Uri uri, {
  required DateTime now,
}) {
  if (method != 'GET' || uri.path != '/rest/v1/vote') return _notFound;
  final all = uri.queryParametersAll;
  final repeated = [
    for (final entry in all.entries)
      if (entry.value.length != 1) entry.key,
  ];
  if (repeated.isNotEmpty) return _refused('repeated keys $repeated');
  final query = uri.queryParameters;

  var area = 'all';
  final areas = query['areas'];
  if (areas != null) {
    // postgrest-dart sends a list containment as cs.{"value"}.
    final match = RegExp(r'^cs\.\{"([a-z-]+)"\}$').firstMatch(areas);
    if (match == null) return _refused('areas filter $areas');
    area = match.group(1)!;
  }

  final timeFilters = {
    for (final key in _timeKeys)
      if (query.containsKey(key)) key: query[key]!,
  };
  String? status;
  for (final entry in _statusFilters.entries) {
    final expected = entry.value;
    if (expected.length == timeFilters.length &&
        expected.entries.every((e) => timeFilters[e.key] == e.value)) {
      status = entry.key;
    }
  }
  if (status == null) return _refused('status filters $timeFilters');

  final known = {..._timeKeys, ..._ignoredKeys, 'areas', 'order', 'offset', 'limit'};
  final unknown = [
    for (final key in query.keys)
      if (!known.contains(key)) key,
  ];
  if (unknown.isNotEmpty) return _refused('unknown keys $unknown');

  final offset = int.tryParse(query['offset'] ?? '0');
  final limit = int.tryParse(query['limit'] ?? '');
  if (offset == null || offset < 0 || limit == null || limit < 1) {
    return _refused('range offset=${query['offset']} limit=${query['limit']}');
  }

  final rows = [
    for (final vote in _votes)
      if (vote.phase == status && (area == 'all' || vote.area == area))
        _row(vote, now),
  ];
  final order = query['order'];
  if (order != null) {
    final match =
        RegExp(r'^(start_at|stop_at|id)\.(asc|desc)(\.nulls(first|last))?$')
            .firstMatch(order);
    if (match == null) return _refused('order $order');
    final field = match.group(1)!;
    final ascending = match.group(2) == 'asc';
    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      final result = (a[field] as Comparable).compareTo(b[field] as Comparable);
      return ascending ? result : -result;
    }

    rows.sort(compare);
  }
  final page = rows.skip(offset).take(limit).toList();
  return VoteListReply(200, page, area: area, voteStatus: status);
}

/// HTTP server on 127.0.0.1 with an OS-assigned port.
///
/// For each request it keeps the method, the path, the reply status and,
/// for an answered vote list, the area, status and returned ids. No header,
/// body or other query value is kept.
class VoteListLoopback {
  VoteListLoopback._(this._server, this._clock, this._log);

  final HttpServer _server;
  final DateTime Function() _clock;
  final void Function(String line) _log;
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];
  final List<String> unexpected = <String>[];

  /// Called after each request is recorded.
  void Function()? onRequest;

  static Future<VoteListLoopback> start({
    DateTime Function()? clock,
    void Function(String line)? log,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final backend = VoteListLoopback._(
      server,
      clock ?? () => DateTime.now().toUtc(),
      log ?? (_) {},
    );
    server.listen(
      (request) => unawaited(backend._handle(request)),
      onError: (Object error) =>
          backend._log('QA_LOOPBACK_SERVER_ERROR ${error.runtimeType}'),
    );
    return backend;
  }

  Uri get base => Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: _server.port,
      );

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    try {
      await request.drain<void>();
    } catch (_) {
      // A client that went away has nothing left to answer.
    }
    final reply = resolveVoteListRequest(
      request.method,
      request.uri,
      now: _clock(),
    );
    final line = '${request.method} ${request.uri.path}';
    final record = <String, Object?>{
      'method': request.method,
      'path': request.uri.path,
      'statusCode': reply.status,
    };
    if (reply.status == 200) {
      record['area'] = reply.area;
      record['voteStatus'] = reply.voteStatus;
      record['ids'] = [
        for (final row in reply.body as List) (row as Map)['id'] as int,
      ];
    } else {
      unexpected.add(line);
    }
    requests.add(record);
    _log('QA_LOOPBACK $line -> ${reply.status}');
    onRequest?.call();
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

/// Configuration for Environment.initTestConfig. Supabase, storage and the
/// CDN point at [base]; every other value is synthetic and never fetched.
Map<String, dynamic> syntheticQaConfig(Uri base) {
  final url = base.toString();
  return <String, dynamic>{
    'supabase': {
      'url': url,
      'anon_key': qaSyntheticAnonKey,
      'storage': {'url': url, 'anon_key': qaSyntheticAnonKey},
    },
    'storage': {
      'cdn_url': '$url/qa-cdn',
      'aws': {
        'access_key_id': 'qa-synthetic-access-key',
        'secret_access_key': 'qa-synthetic-secret',
        'region': 'qa-synthetic-region',
        's3_bucket': 'qa-synthetic-bucket',
        's3_bucket_url': '$url/qa-bucket',
      },
    },
    'logging': {
      'level': 'info',
      'image_load_warning_threshold_seconds': 10,
      'image_load_error_threshold_seconds': 20,
    },
    'sentry': {
      'enable': false,
      'app_dsn': 'http://qa-synthetic-public-key@127.0.0.1:9/1',
      'web_dsn': 'http://qa-synthetic-public-key@127.0.0.1:9/1',
      'sample_rates': {
        'trace': 0.0,
        'profile': 0.0,
        'session': 0.0,
        'error': 0.0,
      },
    },
    'app': {
      'web_domain': url,
      'download_link': 'https://example.invalid/qa-notification/download',
      'app_link_prefix': 'https://example.invalid/qa-notification/link',
      'inapp_appname_prefix': '',
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
  };
}
