import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';

import '../../helpers/mocks/mock_supabase.dart';

void main() {
  group('ConfigService.getConfig', () {
    test('returns value when config exists', () async {
      final client = FakeSupabaseClient();
      client.setTable('config', (query) {
        query.setSelectResult('value', (filter) {
          filter.singleResult = {'value': 'test_value'};
        });
      });

      final service = ConfigService(client);
      final result = await service.getConfig('test_key');
      expect(result, 'test_value');
    });

    test('returns null when config does not exist', () async {
      final client = FakeSupabaseClient();
      client.setTable('config', (query) {
        query.setSelectResult('value', (filter) {
          filter.singleResult = null;
        });
      });

      final service = ConfigService(client);
      final result = await service.getConfig('missing');
      expect(result, isNull);
    });

    test('returns null on error', () async {
      final client = FakeSupabaseClient();
      client.setTable('config', (query) {
        query.setSelectResult('value', (filter) {
          filter.singleError = Exception('DB error');
        });
      });

      final service = ConfigService(client);
      final result = await service.getConfig('bad');
      expect(result, isNull);
    });

    test('different keys return different values', () async {
      final client = FakeSupabaseClient();
      client.setTable('config', (query) {
        query.setSelectResult('value', (filter) {
          filter.singleResult = {'value': 'version_1.0'};
        });
      });

      final service = ConfigService(client);
      final result = await service.getConfig('app_version');
      expect(result, 'version_1.0');
    });
  });
}
