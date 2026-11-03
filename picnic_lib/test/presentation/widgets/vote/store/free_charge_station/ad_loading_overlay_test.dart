import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_overlay.dart';

void main() {
  test(
    'shared ad loader uses the same centered pulse indicator as Internal',
    () {
      expect(AdLoadingOverlay.indicator, isA<MediumPulseLoadingIndicator>());
    },
  );
}
