import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

import '../../helpers/ignore_image_errors.dart';

void main() {
  testWidgets('Environment 미초기화 상태의 외부 HTTP URL은 원문을 보존하고 크래시하지 않는다', (
    tester,
  ) async {
    const imageUrl =
        'https://splash.example.com/scheduled.jpg?token=signed-value';
    expect(Environment.isInitialized, isFalse);

    await pumpWidgetAndIgnoreErrors(
      tester,
      const MaterialApp(
        home: PicnicCachedNetworkImage(
          imageUrl: imageUrl,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, imageUrl);
  });
}
