import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/presentation/splash/responsive_splash.dart';

void main() {
  testWidgets('fills a wide viewport with a bounded contained key image', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1224, 918));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ResponsiveSplash()));

    expect(
      find.byKey(const Key('responsive-splash-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('responsive-splash-key-image')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FittedBox>(
            find.byKey(const Key('responsive-splash-fitted-box')),
          )
          .fit,
      BoxFit.contain,
    );
  });

  testWidgets('renders the transparent splash key asset', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResponsiveSplash()));

    final image = tester.widget<Image>(
      find.byKey(const Key('responsive-splash-key-image')),
    );

    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/splash_key.png',
    );
  });
}
