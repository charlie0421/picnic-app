import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';

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
        onViewComplete: legacyViewResponse,
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
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );

      expect(widget.videoUrl, 'https://test.com/video.mp4');
      expect(widget.ctaUrl, isNull);
      expect(widget.loadAd, isNull);
    });

    test('ctaUrl defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.ctaUrl, isNull);
    });

    test('loadAd defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.loadAd, isNull);
    });

    test('accepts empty video URL', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.videoUrl, '');
    });

    test('with custom key', () {
      final widget = AdShortformFullscreenPage(
        key: const ValueKey('ad-page'),
        videoUrl: 'https://test.com/video.mp4',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.key, const ValueKey('ad-page'));
    });
  });

  group('AdShortformFullscreenPage callback types', () {
    test('onViewComplete returns the typed reward response', () async {
      var called = false;
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {
          called = true;
          return legacyViewResponse();
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
        onViewComplete: legacyViewResponse,
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
        onViewComplete: legacyViewResponse,
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
        onViewComplete: legacyViewResponse,
        onMore: () async {},
        loadAd: () async =>
            (videoUrl: 'https://ad.com/v.mp4', ctaUrl: null, blocked: false),
      );

      final result = await widget.loadAd!();
      expect(result.videoUrl, 'https://ad.com/v.mp4');
      expect(result.ctaUrl, isNull);
    });
  });

  group('reward presentation', () {
    test('wallet-aware response suppresses local dialog/profile UX', () {
      final reward = AdRewardStatusModel.fromJson(
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/ad_reward_granted_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final response = const InternalShortformViewResponse(
        ok: true,
        rewardAdded: 3,
        impressionId: '00000000-0000-4000-8000-000000000402',
        newBonus: null,
      ).copyWith(reward: reward);
      expect(AdShortformLogic.shouldSuppressLocalWalletUx(response), isTrue);
      expect(AdShortformLogic.shouldUseLegacyBonusUx(response), isFalse);
    });

    test('legacy positive reward preserves Bonus success UX', () async {
      final response = await legacyViewResponse();
      expect(AdShortformLogic.shouldSuppressLocalWalletUx(response), isFalse);
      expect(AdShortformLogic.shouldUseLegacyBonusUx(response), isTrue);
      expect(
        AdShortformLogic.legacyBonusSuccessMessage('credited', response),
        'credited (1)',
      );
    });
  });
}

Future<InternalShortformViewResponse> legacyViewResponse() async =>
    const InternalShortformViewResponse(
      ok: true,
      rewardAdded: 1,
      impressionId: '00000000-0000-4000-8000-000000000402',
      newBonus: 1,
    );
