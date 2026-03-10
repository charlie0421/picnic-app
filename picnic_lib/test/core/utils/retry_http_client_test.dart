import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/retry_http_client.dart';

void main() {
  group('NetworkError', () {
    test('기본 생성 시 isRetryable=true', () {
      final error = NetworkError('connection failed');
      expect(error.isRetryable, isTrue);
      expect(error.message, equals('connection failed'));
    });

    test('isRetryable=false로 생성 가능', () {
      final error = NetworkError('fatal error', isRetryable: false);
      expect(error.isRetryable, isFalse);
    });

    test('toString은 NetworkError: prefix 포함', () {
      final error = NetworkError('test message');
      expect(error.toString(), equals('NetworkError: test message'));
    });
  });

  group('NetworkError.isRetryableError', () {
    test('일반 메시지는 재시도 가능', () {
      expect(NetworkError.isRetryableError('timeout'), isTrue);
      expect(NetworkError.isRetryableError('server error'), isTrue);
    });

    test('content size exceeds는 재시도 불가', () {
      expect(
        NetworkError.isRetryableError('content size exceeds limit'),
        isFalse,
      );
    });

    test('connection closed는 재시도 불가', () {
      expect(
        NetworkError.isRetryableError('connection closed before complete'),
        isFalse,
      );
    });

    test('connection reset은 재시도 불가', () {
      expect(
        NetworkError.isRetryableError('connection reset by peer'),
        isFalse,
      );
    });
  });

  group('RetryHttpClient 구성', () {
    test('커스텀 설정 확인', () {
      final client = RetryHttpClient(
        http.Client(),
        maxAttempts: 5,
        timeout: const Duration(seconds: 60),
      );
      expect(client.maxAttempts, equals(5));
      expect(client.timeout, equals(const Duration(seconds: 60)));
      client.close();
    });

    test('기본값 적용 확인', () {
      final client = RetryHttpClient(http.Client());
      expect(client.maxAttempts, equals(3));
      expect(client.timeout, equals(const Duration(seconds: 30)));
      client.close();
    });
  });
}
