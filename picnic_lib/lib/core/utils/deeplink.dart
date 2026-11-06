import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOException;

import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The longest time a share waits for a Branch link.
const branchLinkTimeout = Duration(seconds: 10);

/// Why a Branch link request did not give a usable link.
enum BranchLinkFailureKind { httpStatus, transport, timeout, invalidResponse }

/// A failed Branch link request. Its text holds only closed values: the kind
/// and, for [BranchLinkFailureKind.httpStatus], the HTTP status. It never
/// holds the title, the destination, the Branch key or the response body.
final class BranchLinkFailure implements Exception {
  const BranchLinkFailure(this.kind) : statusCode = null;

  BranchLinkFailure.status(int status)
    : kind = BranchLinkFailureKind.httpStatus,
      statusCode = status >= 100 && status <= 599 ? status : null;

  final BranchLinkFailureKind kind;
  final int? statusCode;

  /// Whether Sentry gets this failure: only a Branch answer that the app
  /// cannot use. A transport failure or a timeout is a user network
  /// condition. The app's `beforeSend` drops the same failures from other
  /// paths (ClientException, SocketException, HandshakeException, wrapped
  /// timeouts) as user network noise.
  bool get isReportable =>
      kind == BranchLinkFailureKind.httpStatus ||
      kind == BranchLinkFailureKind.invalidResponse;

  @override
  String toString() => statusCode == null
      ? 'BranchLinkFailure(kind: ${kind.name})'
      : 'BranchLinkFailure(kind: ${kind.name}, status: $statusCode)';
}

typedef BranchLinkFailureReporter =
    void Function(BranchLinkFailure failure, StackTrace stackTrace);

/// Creates a Branch short link. Throws [BranchLinkFailure] when Branch does
/// not answer 200 with an https link.
Future<String> createBranchLink(String? title, String? longUrl) async {
  final url = Uri.parse('https://api2.branch.io/v1/url');
  final branchKey = Environment.branchKey;

  logger.i('Creating Branch link: $title, $longUrl');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'branch_key': branchKey,
      'data': {'title': title, '\$desktop_url': longUrl},
    }),
  );

  if (response.statusCode != 200) {
    throw BranchLinkFailure.status(response.statusCode);
  }
  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    throw const BranchLinkFailure(BranchLinkFailureKind.invalidResponse);
  }
  final link = decoded is Map ? decoded['url'] : null;
  if (link is! String || !_isHttpsLink(link)) {
    throw const BranchLinkFailure(BranchLinkFailureKind.invalidResponse);
  }
  return link;
}

bool _isHttpsLink(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// The link for a share: a Branch link, or null when Branch fails or does
/// not answer in [timeout]. With null, `ShareUtils.shareToSocial` uses the
/// configured download link, so the share continues.
///
/// Each failure goes to [onFailure] with closed values only. The default
/// reporter logs every failure and sends a Sentry warning only when
/// [BranchLinkFailure.isReportable]. An error that is not a Branch request
/// failure is a defect and is rethrown.
Future<String?> createShareLink(
  String? title,
  String? longUrl, {
  Duration timeout = branchLinkTimeout,
  BranchLinkFailureReporter? onFailure,
}) async {
  try {
    return await createBranchLink(title, longUrl).timeout(timeout);
  } catch (error, stackTrace) {
    final failure = switch (error) {
      BranchLinkFailure() => error,
      TimeoutException() => const BranchLinkFailure(
        BranchLinkFailureKind.timeout,
      ),
      // IOException covers SocketException and the TLS failures
      // (HandshakeException) that IOClient does not wrap.
      http.ClientException() ||
      IOException() => const BranchLinkFailure(BranchLinkFailureKind.transport),
      _ => null,
    };
    if (failure == null) rethrow;
    try {
      (onFailure ?? _reportBranchLinkFailure)(failure, stackTrace);
    } catch (reportError) {
      logger.w('Branch link failure report failed: ${reportError.runtimeType}');
    }
    return null;
  }
}

void _reportBranchLinkFailure(BranchLinkFailure failure, StackTrace stack) {
  logger.w('Branch link unavailable, sharing the download link: $failure');
  if (!failure.isReportable) return;
  unawaited(
    Sentry.captureException(
      failure,
      stackTrace: stack,
      withScope: (scope) {
        scope.level = SentryLevel.warning;
        scope.setTag('branch_link_failure_kind', failure.kind.name);
        if (failure.statusCode != null) {
          scope.setTag('branch_link_status', '${failure.statusCode}');
        }
        scope.fingerprint = ['branch-share-link-failure', failure.kind.name];
      },
    ).then<void>(
      (_) {},
      onError: (Object e) =>
          logger.w('Branch link Sentry report failed: ${e.runtimeType}'),
    ),
  );
}

Future<String> getLongUrl(String shortUrl) async {
  final branchKey = Environment.branchKey;
  final response = await http.get(
    Uri.parse(
      'https://api2.branch.io/v1/url?url=${Uri.encodeComponent(shortUrl)}&branch_key=$branchKey',
    ),
  );

  if (response.statusCode == 200) {
    logger.i(response.body);
    return jsonDecode(response.body)['long_url'];
  } else {
    throw Exception('Failed to get long URL');
  }
}
