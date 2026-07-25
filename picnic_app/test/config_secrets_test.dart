import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const environments = ['dev', 'local', 'prod'];

  for (final environment in environments) {
    test('$environment 설정은 장기 비밀키를 번들하지 않는다', () async {
      final file = File('config/$environment.json');
      final config =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final storage = config['storage'] as Map<String, dynamic>;
      final aws = storage['aws'] as Map<String, dynamic>;
      final apiKeys = config['api_keys'] as Map<String, dynamic>;

      expect(
        (aws['access_key_id'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment AWS access key must not be bundled',
      );
      expect(
        (aws['secret_access_key'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment AWS secret key must not be bundled',
      );
      expect(
        (apiKeys['deepl'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment DeepL key must not be bundled',
      );
      expect(
        (apiKeys['youtube'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment YouTube key must not be bundled',
      );
    });
  }
}
