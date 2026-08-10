import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/presentation/splash/responsive_splash.dart';

void main() {
  const viewports = <String, Size>{
    'phone portrait': Size(393, 852),
    'Fold 8 unfolded portrait': Size(1848, 2448),
    'Fold 8 unfolded landscape': Size(2448, 1848),
  };

  for (final viewport in viewports.entries) {
    testWidgets(
      'fills the ${viewport.key} viewport with a contained key image',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport.value);
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
        expect(
          tester.takeException(),
          isNull,
          reason: '${viewport.key} layout must not overflow',
        );
      },
    );
  }

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
