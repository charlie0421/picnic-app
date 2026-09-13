import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

final class _HostAppAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'assets/app_icon_128.png') {
      return rootBundle.load(key);
    }

    final candidates = [
      File('../picnic_app/assets/app_icon_128.png'),
      File('picnic_app/assets/app_icon_128.png'),
    ];
    final icon = candidates.firstWhere((candidate) => candidate.existsSync());
    return ByteData.sublistView(await icon.readAsBytes());
  }
}

Widget _buildPulseApp({required Widget child, bool disableAnimations = false}) {
  return DefaultAssetBundle(
    bundle: _HostAppAssetBundle(),
    child: ScreenUtilInit(
      designSize: kAppDesignSize,
      minTextAdapt: true,
      splitScreenMode: kAppSplitScreenMode,
      child: MaterialApp(
        builder: (context, navigator) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: navigator!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void _useProductionViewport(WidgetTester tester) {
  tester.view.physicalSize = kAppDesignSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('small pulse keeps its 24px footprint in a roomy parent', (
    tester,
  ) async {
    _useProductionViewport(tester);

    await tester.pumpWidget(
      _buildPulseApp(
        disableAnimations: true,
        child: const Center(child: SmallPulseLoadingIndicator()),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(PulseLoadingIndicator)),
      const Size.square(24),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stops the pulse at full visibility', (
    tester,
  ) async {
    _useProductionViewport(tester);

    await tester.pumpWidget(
      _buildPulseApp(
        child: const PulseLoadingIndicator(
          key: ValueKey('pulse'),
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(
      _buildPulseApp(
        disableAnimations: true,
        child: const PulseLoadingIndicator(
          key: ValueKey('pulse'),
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 20),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 1),
    );

    final pulse = find.byKey(const ValueKey('pulse'));
    final transform = tester.widget<Transform>(
      find.descendant(of: pulse, matching: find.byType(Transform)),
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(of: pulse, matching: find.byType(Opacity)),
    );
    expect(transform.transform.getMaxScaleOnAxis(), 1);
    expect(opacity.opacity, 1);
    expect(tester.takeException(), isNull);
  });
}
