import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';

void main() {
  group('AppVersionModel', () {
    test('기본 생성', () {
      const model = AppVersionModel(
        id: 1,
        ios: {'minimum': '1.0.0', 'latest': '2.0.0'},
        android: {'minimum': '1.0.0', 'latest': '2.0.0'},
        macos: {'minimum': '1.0.0', 'latest': '1.5.0'},
        windows: {'minimum': '1.0.0'},
        linux: {},
      );
      expect(model.id, equals(1));
      expect(model.ios['minimum'], equals('1.0.0'));
      expect(model.ios['latest'], equals('2.0.0'));
      expect(model.android['latest'], equals('2.0.0'));
      expect(model.macos['latest'], equals('1.5.0'));
      expect(model.windows.containsKey('minimum'), isTrue);
      expect(model.linux, isEmpty);
    });

    test('빈 맵 허용', () {
      const model = AppVersionModel(
        id: 2,
        ios: {},
        android: {},
        macos: {},
        windows: {},
        linux: {},
      );
      expect(model.ios, isEmpty);
      expect(model.android, isEmpty);
    });
  });
}
