// Real Sentry hub under test; only the native binding, one enricher and the
// transport are fakes (same approach as purchase_diagnostics_test.dart).
// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/profile_image_diagnostics.dart';
import 'package:picnic_lib/core/services/purchase_diagnostics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_flutter/src/integrations/load_contexts_integration.dart';
import 'package:sentry_flutter/src/native/sentry_native_binding.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

const _secret = 'synthetic-secret';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('errorCode keeps only closed values', () {
    final cases = <String, (Object, String)>{
      'known platform code': (
        PlatformException(code: 'photo_access_denied'),
        'photo_access_denied',
      ),
      'short unknown platform code': (
        PlatformException(code: _secret),
        'unknown',
      ),
      'storage status': (StorageException('x', statusCode: '403'), '403'),
      'storage path as status': (
        StorageException('x', statusCode: '/private/$_secret.jpg'),
        'unknown',
      ),
      'storage status with a sign': (
        StorageException('x', statusCode: '+403'),
        'unknown',
      ),
      'storage status with a leading zero': (
        StorageException('x', statusCode: '0403'),
        'unknown',
      ),
      'storage status out of range': (
        StorageException('x', statusCode: '600'),
        'unknown',
      ),
      'storage status missing': (StorageException('x'), 'unknown'),
      'known PostgREST code': (
        const PostgrestException(message: 'x', code: 'PGRST301'),
        'PGRST301',
      ),
      'known SQL code': (
        const PostgrestException(message: 'x', code: '42501'),
        '42501',
      ),
      'PostgREST HTTP status': (
        const PostgrestException(message: 'x', code: '502'),
        '502',
      ),
      'short unknown PostgREST code': (
        const PostgrestException(message: 'x', code: _secret),
        'unknown',
      ),
      'PostgREST code missing': (
        const PostgrestException(message: 'x'),
        'unknown',
      ),
      'error without a code': (StateError(_secret), 'unknown'),
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        expect(
          ProfileImageDiagnostics.errorCode(entry.value.$1),
          entry.value.$2,
        );
      });
    }
  });

  group('sanitizeForSend', () {
    test('returns an unrelated event and its hint unchanged', () {
      final event = SentryEvent(tags: {'k': _secret});
      final hint = Hint.withAttachment(
        SentryAttachment.fromIntList(const [1], 'photo.jpg'),
      )..screenshot = SentryAttachment.fromIntList(const [2], 'screen.png');

      final result = ProfileImageDiagnostics.sanitizeForSend(event, hint);

      expect(identical(result, event), isTrue);
      expect(event.tags, {'k': _secret});
      expect(hint.attachments, hasLength(1));
      expect(hint.screenshot, isNotNull);
    });
  });

  group('through a real hub after enrichment', () {
    late _Harness sentry;

    setUp(() async {
      sentry = _Harness();
      await sentry.start();
    });

    tearDown(() => sentry.stop());

    test(
      'a report keeps its fixed values when an enricher overwrites them',
      () async {
        sentry.enricher.overwriteReportFields = true;

        ProfileImageDiagnostics.report(
          ProfileImagePhase.upload,
          StorageException(_secret, statusCode: '403'),
          StackTrace.current,
        );
        final sent = await sentry.nextSent();

        expect(sent.event['tags'], {
          'profile_image_phase': 'upload',
          'profile_image_error_type': 'StorageException',
          'profile_image_error_code': '403',
        });
        expect(sent.event['fingerprint'], [
          'profile-image-failure',
          'upload',
          'StorageException',
        ]);
        expect(sent.event['level'], 'error');
        expect(jsonEncode(sent.event), isNot(contains(_secret)));
        expect(jsonEncode(sent.event), isNot(contains('native-secret')));
        expect(sent.attachments, isEmpty);
      },
    );

    test('a report keeps its own stack trace', () async {
      ProfileImageDiagnostics.report(
        ProfileImagePhase.read,
        const FormatException(_secret),
        _stackFromNamedFunction(),
      );
      final sent = await sentry.nextSent();

      final exception =
          ((sent.event['exception'] as Map)['values'] as List).single as Map;
      expect(exception['type'], 'ProfileImageFailureReport');
      expect(exception['value'], isNot(contains(_secret)));
      expect(jsonEncode(exception), contains('_stackFromNamedFunction'));
    });

    test(
      'a purchase report keeps the purchase contract and the native data',
      () async {
        PurchaseDiagnostics.reportFailure(
          stage: PurchaseFailureStage.settlement,
          productId: 'STAR100',
          userId: 'user-a',
          error: TimeoutException('slow'),
        );
        final sent = await sentry.nextSent();

        final tags = sent.event['tags'] as Map;
        expect(tags['purchase.stage'], 'settlement');
        expect(tags['native_tag'], 'native-secret');
        expect((sent.event['user'] as Map)['id'], 'user-a');
        expect((sent.event['breadcrumbs'] as List?) ?? const [], isEmpty);
        expect(sent.attachments, containsAll(const ['screen.png', 'hint.jpg']));
      },
    );
  });
}

StackTrace _stackFromNamedFunction() => StackTrace.current;

class _SentEnvelope {
  _SentEnvelope(this.event, this.attachments);

  final Map<String, dynamic> event;
  final List<String> attachments;
}

class _EnvelopeTransport implements Transport {
  final sent = <_SentEnvelope>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    Map<String, dynamic>? event;
    final attachments = <String>[];
    for (final item in envelope.items) {
      if (item.header.type == 'event') {
        final data = await item.dataFactory();
        event = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      } else if (item.header.type == 'attachment') {
        attachments.add(item.header.fileName ?? '');
      }
    }
    if (event != null) sent.add(_SentEnvelope(event, attachments));
    return envelope.header.eventId;
  }
}

class _FakeNative extends Fake implements SentryNativeBinding {
  @override
  bool get supportsLoadContexts => true;

  @override
  FutureOr<Map<String, dynamic>?> loadContexts() => {
    'tags': {'native_tag': 'native-secret'},
    'extra': {'native_extra': 'native-secret'},
    'user': {'id': 'native-secret-install'},
    'breadcrumbs': [
      {
        'message': 'native-secret-breadcrumb',
        'category': 'log',
        'level': 'info',
        'timestamp': '2026-11-01T00:00:00.000Z',
      },
    ],
  };
}

/// Runs after the native contexts. When [overwriteReportFields] is set, it
/// also changes the fields a profile image report fixes.
class _Enricher implements EventProcessor {
  bool overwriteReportFields = false;

  @override
  SentryEvent? apply(SentryEvent event, Hint hint) {
    hint
      ..screenshot = SentryAttachment.fromIntList(const [1], 'screen.png')
      ..attachments.add(SentryAttachment.fromIntList(const [2], 'hint.jpg'));
    if (overwriteReportFields) {
      event
        ..tags = {
          ...?event.tags,
          'profile_image_error_code': _secret,
          'profile_image_phase': _secret,
        }
        ..fingerprint = [_secret]
        ..level = SentryLevel.debug
        ..request = SentryRequest(url: 'https://cdn.test/$_secret.jpg');
    }
    return event;
  }
}

/// The same `beforeSend` calls, in the same order, as
/// AppInitializer.initializeSentry.
SentryEvent _beforeSend(SentryEvent event, Hint hint) {
  event = PurchaseDiagnostics.sanitizeForSend(event, hint);
  return ProfileImageDiagnostics.sanitizeForSend(event, hint);
}

class _Harness {
  final transport = _EnvelopeTransport();
  final enricher = _Enricher();

  Future<void> start() async {
    final options = SentryFlutterOptions()
      ..dsn = 'https://public@o0.ingest.sentry.io/0'
      ..automatedTestMode = true
      ..transport = transport
      ..autoInitializeNativeSdk = false
      ..enableDartSymbolication = false
      ..enableDeduplication = false
      ..beforeSend = _beforeSend;
    options
      ..addIntegration(LoadContextsIntegration(_FakeNative()))
      ..addEventProcessor(enricher);
    await Sentry.init((o) => o.debug = false, options: options);
  }

  Future<void> stop() => Sentry.close();

  Future<_SentEnvelope> nextSent() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (transport.sent.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(transport.sent, hasLength(1));
    return transport.sent.removeAt(0);
  }
}
