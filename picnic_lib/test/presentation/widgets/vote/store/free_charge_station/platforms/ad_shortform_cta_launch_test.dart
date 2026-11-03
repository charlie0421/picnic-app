import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

/// `openAdCta` is the '더보기' tap: it records the click on the server and then
/// hands the user to the advertiser's landing page.
void main() {
  group('openAdCta', () {
    test('records the click before handing off to the browser', () async {
      final order = <String>[];
      final launched = await openAdCta(
        'https://advertiser.example/landing',
        launch: (uri, {required external}) async {
          order.add('launch:${uri.host}:$external');
          return true;
        },
        reportClick: () async => order.add('report'),
      );

      expect(launched, isTrue);
      // Order matters: launching pushes the app to the background and iOS can
      // suspend an in-flight request, so a click reported afterwards is lost.
      expect(order, ['report', 'launch:advertiser.example:true']);
    });

    test('does not wait for the server before launching', () async {
      final gate = Completer<void>();
      var launched = false;
      final pending = openAdCta(
        'https://advertiser.example/landing',
        launch: (uri, {required external}) async {
          launched = true;
          return true;
        },
        reportClick: () => gate.future,
      );

      await pumpEventQueue();
      expect(
        launched,
        isTrue,
        reason: 'the landing page must open even if the stats write hangs',
      );
      gate.complete();
      expect(await pending, isTrue);
    });

    test('a failing click report never blocks the landing page', () async {
      var launches = 0;
      final launched = await openAdCta(
        'https://advertiser.example/landing',
        launch: (uri, {required external}) async {
          launches++;
          return true;
        },
        reportClick: () async => throw StateError('edge down'),
      );

      expect(launched, isTrue);
      expect(launches, 1);
    });

    test('falls back to the in-app launcher and still reports once', () async {
      final order = <String>[];
      final launched = await openAdCta(
        'https://advertiser.example/landing',
        launch: (uri, {required external}) async {
          order.add('launch:$external');
          if (external) throw Exception('no activity found');
          return true;
        },
        reportClick: () async => order.add('report'),
      );

      expect(launched, isTrue);
      expect(order, ['report', 'launch:true', 'launch:false']);
    });

    test('an unparseable url neither reports nor launches', () async {
      var launches = 0;
      var reports = 0;
      final launched = await openAdCta(
        '::not a url::',
        launch: (uri, {required external}) async {
          launches++;
          return true;
        },
        reportClick: () async => reports++,
      );

      expect(launched, isFalse);
      expect(launches, 0);
      expect(reports, 0);
    });

    test('works without a reporter at all', () async {
      final launched = await openAdCta(
        'https://advertiser.example/landing',
        launch: (uri, {required external}) async => true,
      );
      expect(launched, isTrue);
    });
  });
}
