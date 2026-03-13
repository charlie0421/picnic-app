import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncPolicy', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'policy': [
          {
            'id': 1,
            'type': 'terms',
            'language': 'ko',
            'content': '이용약관 내용',
            'version': '1.0',
            'created_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 2,
            'type': 'terms',
            'language': 'en',
            'content': 'Terms of service',
            'version': '1.0',
            'created_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 3,
            'type': 'privacy',
            'language': 'ko',
            'content': '개인정보 처리방침',
            'version': '1.0',
            'created_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 4,
            'type': 'privacy',
            'language': 'en',
            'content': 'Privacy policy',
            'version': '1.0',
            'created_at': '2026-01-01T00:00:00Z',
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches policy data from supabase', () async {
      final result = await container.read(asyncPolicyProvider.future);
      expect(result.termsKo.content, '이용약관 내용');
      expect(result.termsEn.content, 'Terms of service');
      expect(result.privacyKo.content, '개인정보 처리방침');
      expect(result.privacyEn.content, 'Privacy policy');
    });

    test('policy versions are correct', () async {
      final result = await container.read(asyncPolicyProvider.future);
      expect(result.termsKo.version, '1.0');
      expect(result.termsEn.version, '1.0');
      expect(result.privacyKo.version, '1.0');
      expect(result.privacyEn.version, '1.0');
    });
  });
}
