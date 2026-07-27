import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet currency assets are transparent 192px PNGs', () async {
    for (final path in const [
      'assets/icons/store/currency_star_candy.png',
      'assets/icons/store/currency_bonus_star_candy.png',
      'assets/icons/store/currency_cotton_candy.png',
    ]) {
      final bytes = File(path).readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 192, reason: path);
      expect(frame.image.height, 192, reason: path);
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels, isNotNull);
      final rgba = pixels!.buffer.asUint8List();
      expect(
        Iterable<int>.generate(
          rgba.length ~/ 4,
        ).any((i) => rgba[i * 4 + 3] < 255),
        isTrue,
        reason: '$path must retain alpha',
      );
    }
  });
}
