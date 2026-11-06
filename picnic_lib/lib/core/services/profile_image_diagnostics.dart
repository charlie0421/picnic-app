import 'dart:async';
import 'dart:io' show FileSystemException, SocketException;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

/// A step of the profile photo change. Its name is a report tag value.
enum ProfileImagePhase { pick, crop, read, upload, update }

/// Sentry reports for the profile photo change on MyProfilePage.
///
/// A report carries only values from closed sets: the phase, the error type
/// and the error code. SDK error text is never copied, shortened or
/// pattern-matched into a report: an error code from a platform channel, a
/// storage response body or a PostgREST body can carry a device path, a
/// storage path (with the account id) or other server text.
///
/// The scope that [report] clones is not enough. On iOS and Android,
/// `LoadContextsIntegration` runs after the scope and adds the native tags,
/// extras, user and breadcrumbs, and other enrichers can add request data
/// and attachments. So `beforeSend` calls [sanitizeForSend], which rebuilds a
/// report from a closed list of fields after all enrichment.
class ProfileImageDiagnostics {
  const ProfileImageDiagnostics._();

  /// The value sent for every code outside the closed sets.
  static const unknownCode = 'unknown';

  static const _hintKey = 'picnic.profile_image_diagnostics';

  /// Platform codes that the image picker and the image cropper document.
  static const _platformCodes = {
    'already_active',
    'camera_access_denied',
    'crop_error',
    'invalid_image',
    'invalid_source',
    'multiple_request',
    'no_available_camera',
    'photo_access_denied',
  };

  /// PostgREST and PostgreSQL codes that a user_profiles update can return.
  static const _postgrestCodes = {
    'PGRST000',
    'PGRST001',
    'PGRST002',
    'PGRST003',
    'PGRST116',
    'PGRST204',
    'PGRST301',
    'PGRST302',
    '22P02',
    '23514',
    '40001',
    '40P01',
    '42501',
    '42703',
    '42P01',
    '53300',
    '57014',
  };

  /// Whether [error] is an external failure that [phase] expects and handles.
  /// Every other error is a defect: the caller rethrows it.
  static bool isExpectedFailure(ProfileImagePhase phase, Object error) =>
      switch (phase) {
        ProfileImagePhase.pick ||
        ProfileImagePhase.crop => error is PlatformException,
        ProfileImagePhase.read => error is FileSystemException,
        ProfileImagePhase.upload =>
          error is StorageException || _isTransportFailure(error),
        ProfileImagePhase.update =>
          error is PostgrestException || _isTransportFailure(error),
      };

  static bool _isTransportFailure(Object error) =>
      error is http.ClientException ||
      error is SocketException ||
      error is TimeoutException ||
      error is AuthException;

  /// Reports one handled failure. Fire-and-forget; never throws.
  ///
  /// The original [error] is not sent. Only its type and code are sent, with
  /// [stackTrace] for diagnosis.
  static void report(
    ProfileImagePhase phase,
    Object error,
    StackTrace stackTrace,
  ) {
    try {
      final marker = _ReportMarker(
        phase: phase.name,
        type: errorType(error),
        code: errorCode(error),
      );
      unawaited(
        Sentry.captureException(
          ProfileImageFailureReport._(marker),
          stackTrace: stackTrace,
          hint: Hint.withMap({_hintKey: marker}),
          withScope: (scope) {
            // The clone only. The global scope keeps its attachments.
            scope.clearAttachments();
            marker.tags.forEach(scope.setTag);
            scope.fingerprint = marker.fingerprint;
          },
        ).then<void>((_) {}, onError: _logReportFailure),
      );
    } catch (e) {
      _logReportFailure(e);
    }
  }

  static void _logReportFailure(Object error) =>
      logger.w('Profile image Sentry report failed: ${error.runtimeType}');

  /// Rebuilds a profile image report from a closed list of fields after all
  /// enrichment, and removes its attachments. Called from `beforeSend`.
  /// Every other event is returned unchanged.
  static SentryEvent sanitizeForSend(SentryEvent event, Hint hint) {
    final marker = hint.get(_hintKey);
    if (marker is! _ReportMarker) return event;

    // The envelope takes these after beforeSend. A screenshot or an
    // attachment could show the selected photo.
    hint
      ..attachments.clear()
      ..screenshot = null
      ..viewHierarchy = null
      ..response = null;

    final device = event.contexts.device;
    final os = event.contexts.operatingSystem;
    final app = event.contexts.app;
    return SentryEvent(
      eventId: event.eventId,
      timestamp: event.timestamp,
      platform: event.platform,
      release: event.release,
      dist: event.dist,
      environment: event.environment,
      sdk: event.sdk,
      level: SentryLevel.error,
      tags: marker.tags,
      fingerprint: marker.fingerprint,
      // Built from the report and its stack trace only.
      exceptions: event.exceptions,
      threads: event.threads,
      // Needed to symbolicate a --split-debug-info stack trace.
      debugMeta: event.debugMeta,
      contexts: Contexts(
        device: device == null
            ? null
            : SentryDevice(
                model: device.model,
                family: device.family,
                simulator: device.simulator,
              ),
        operatingSystem: os == null
            ? null
            : SentryOperatingSystem(name: os.name, version: os.version),
        app: app == null
            ? null
            : SentryApp(version: app.version, build: app.build),
      ),
    );
  }

  /// The type name to report for [error], from a closed set.
  static String errorType(Object error) => switch (error) {
    PlatformException() => 'PlatformException',
    FileSystemException() => 'FileSystemException',
    StorageException() => 'StorageException',
    ProfileImageEmptyStorageKey() => 'EmptyStorageKey',
    PostgrestException() => 'PostgrestException',
    AuthException() => 'AuthException',
    http.ClientException() => 'ClientException',
    SocketException() => 'SocketException',
    TimeoutException() => 'TimeoutException',
    _ => 'unknown',
  };

  /// The code to report for [error]: a known code, a valid HTTP status, or
  /// [unknownCode].
  static String errorCode(Object error) => switch (error) {
    PlatformException(:final code) =>
      _platformCodes.contains(code) ? code : unknownCode,
    StorageException(:final statusCode) => _httpStatus(statusCode),
    PostgrestException(:final code) =>
      _postgrestCodes.contains(code) ? code! : _httpStatus(code),
    _ => unknownCode,
  };

  /// [value] if it is the canonical form of an HTTP status (100 to 599).
  static String _httpStatus(String? value) {
    if (value == null) return unknownCode;
    final status = int.tryParse(value);
    if (status == null || status < 100 || status > 599) return unknownCode;
    return value == '$status' ? value : unknownCode;
  }
}

/// The storage accepted an upload but returned no object key.
final class ProfileImageEmptyStorageKey implements Exception {
  const ProfileImageEmptyStorageKey();

  @override
  String toString() => 'ProfileImageEmptyStorageKey';
}

/// The exception that a profile image report sends instead of the original
/// error. Its text holds only the phase, the type and the code.
final class ProfileImageFailureReport implements Exception {
  const ProfileImageFailureReport._(this._marker);

  final _ReportMarker _marker;

  @override
  String toString() =>
      'ProfileImageFailure(phase: ${_marker.phase}, '
      'type: ${_marker.type}, code: ${_marker.code})';
}

/// Identifies a profile image report inside `beforeSend` and holds its
/// fixed values.
@immutable
class _ReportMarker {
  const _ReportMarker({
    required this.phase,
    required this.type,
    required this.code,
  });

  final String phase;
  final String type;
  final String code;

  Map<String, String> get tags => {
    'profile_image_phase': phase,
    'profile_image_error_type': type,
    'profile_image_error_code': code,
  };

  List<String> get fingerprint => ['profile-image-failure', phase, type];
}
