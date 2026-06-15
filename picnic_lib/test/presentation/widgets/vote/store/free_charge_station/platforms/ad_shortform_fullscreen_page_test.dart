import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';

/// Coverage-focused tests for AdShortformFullscreenPage.
///
/// The widget depends on VideoPlayerController and SystemChrome for actual
/// video playback and immersive mode, which are not available in headless
/// widget tests. We test constructor parameters and basic initialization.
void main() {
  setUpAll(initTestEnvironment);

  group('AdShortformFullscreenPage constructor', () {
    test('accepts all parameters', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: 'https://test.com/video.mp4',
        ctaUrl: 'https://test.com/cta',
        onViewComplete: () async {},
        onMore: () async {},
        loadAd: () async => (
          videoUrl: 'https://test.com/ad.mp4',
          ctaUrl: 'https://cta.com',
          blocked: false,
        ),
      );

      expect(widget.videoUrl, 'https://test.com/video.mp4');
      expect(widget.ctaUrl, 'https://test.com/cta');
      expect(widget.onViewComplete, isNotNull);
      expect(widget.onMore, isNotNull);
      expect(widget.loadAd, isNotNull);
    });

    test('accepts minimal parameters', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: 'https://test.com/video.mp4',
        onViewComplete: () async {},
        onMore: () async {},
      );

      expect(widget.videoUrl, 'https://test.com/video.mp4');
      expect(widget.ctaUrl, isNull);
      expect(widget.loadAd, isNull);
    });

    test('ctaUrl defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {},
      );
      expect(widget.ctaUrl, isNull);
    });

    test('loadAd defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {},
      );
      expect(widget.loadAd, isNull);
    });

    test('accepts empty video URL', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {},
      );
      expect(widget.videoUrl, '');
    });

    test('with custom key', () {
      final widget = AdShortformFullscreenPage(
        key: const ValueKey('ad-page'),
        videoUrl: 'https://test.com/video.mp4',
        onViewComplete: () async {},
        onMore: () async {},
      );
      expect(widget.key, const ValueKey('ad-page'));
    });
  });

  group('AdShortformFullscreenPage callback types', () {
    test('onViewComplete is Future<void> Function()', () async {
      var called = false;
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {
          called = true;
        },
        onMore: () async {},
      );
      await widget.onViewComplete();
      expect(called, isTrue);
    });

    test('onMore is Future<void> Function()', () async {
      var called = false;
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {
          called = true;
        },
      );
      await widget.onMore();
      expect(called, isTrue);
    });

    test('loadAd returns record with videoUrl and ctaUrl', () async {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {},
        loadAd: () async => (
          videoUrl: 'https://ad.com/v.mp4',
          ctaUrl: 'https://ad.com/cta',
          blocked: false,
        ),
      );

      final result = await widget.loadAd!();
      expect(result.videoUrl, 'https://ad.com/v.mp4');
      expect(result.ctaUrl, 'https://ad.com/cta');
    });

    test('loadAd can return null ctaUrl', () async {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {},
        onMore: () async {},
        loadAd: () async =>
            (videoUrl: 'https://ad.com/v.mp4', ctaUrl: null, blocked: false),
      );

      final result = await widget.loadAd!();
      expect(result.videoUrl, 'https://ad.com/v.mp4');
      expect(result.ctaUrl, isNull);
    });
  });
}
