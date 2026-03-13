import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';

void main() {
  group('TrianglePainter', () {
    test('shouldRepaint returns false', () {
      final painter1 = TrianglePainter(color: Colors.red);
      final painter2 = TrianglePainter(color: Colors.blue);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('paint does not throw', () {
      final painter = TrianglePainter(color: Colors.red);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(100, 50)),
        returnsNormally,
      );
    });

    test('constructor sets color', () {
      final painter = TrianglePainter(color: Colors.green);
      expect(painter.color, Colors.green);
    });
  });
}
