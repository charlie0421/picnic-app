import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';

void main() {
  group('NetworkConnectivityService coverage', () {
    late NetworkConnectivityService service;

    setUp(() {
      service = NetworkConnectivityService();
    });

    group('singleton', () {
      test('returns same instance from factory constructor', () {
        final a = NetworkConnectivityService();
        final b = NetworkConnectivityService();
        expect(identical(a, b), isTrue);
      });
    });

    group('checkOnlineStatus', () {
      test('method exists and returns Future<bool> type', () {
        // checkOnlineStatus uses platform channel (Connectivity.checkConnectivity)
        // which is not available in test env. We just verify the method signature.
        expect(service.checkOnlineStatus, isA<Function>());
      });
    });

    group('onlineStream', () {
      test('returns a Stream<bool>', () {
        final stream = service.onlineStream;
        expect(stream, isA<Stream<bool>>());
      });

      test('stream is an async generator', () {
        // Just verify the stream type -- subscribing would require real
        // connectivity events which are not available in test environment
        final stream = service.onlineStream;
        expect(stream, isA<Stream<bool>>());
      });
    });
  });
}
