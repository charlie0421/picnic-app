import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  final loader = FontLoader('Pretendard')
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Regular.otf',
      ),
    )
    ..addFont(
      rootBundle.load(
        'packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Bold.otf',
      ),
    );
  await loader.load();
}
