import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/ui/common_gradient.dart';

import '../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('Common Gradients', () {
    test('commonGradient is a LinearGradient', () {
      expect(commonGradient, isA<LinearGradient>());
    });

    test('commonGradientVertical is a LinearGradient', () {
      expect(commonGradientVertical, isA<LinearGradient>());
    });

    test('commonGradientReverse is a LinearGradient', () {
      expect(commonGradientReverse, isA<LinearGradient>());
    });

    test('voteGradient is a LinearGradient', () {
      expect(voteGradient, isA<LinearGradient>());
    });

    test('goldGradient is a LinearGradient', () {
      expect(goldGradient, isA<LinearGradient>());
    });

    test('silverGradient is a LinearGradient', () {
      expect(silverGradient, isA<LinearGradient>());
    });

    test('bronzeGradient is a LinearGradient', () {
      expect(bronzeGradient, isA<LinearGradient>());
    });

    test('switchThumbGradient is a RadialGradient', () {
      expect(switchThumbGradient, isA<RadialGradient>());
    });

    test('switchBoxShadow is a BoxShadow', () {
      expect(switchBoxShadow, isA<BoxShadow>());
    });
  });
}
