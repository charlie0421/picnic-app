import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_order.dart';

void main() {
  test('default ad order puts AdMob in global slot #1', () {
    expect(defaultAdOrder, <String>['admob', 'internal-shortform', 'pangle']);
  });

  test(
    'available order preserves configured order and removes unavailable ads',
    () {
      expect(
        resolveAdOrder(
          available: {
            'admob': true,
            'internal-shortform': false,
            'pangle': true,
          },
        ),
        <String>['admob', 'pangle'],
      );
    },
  );
}
