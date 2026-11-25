import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_measurement.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_reporter.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

VideoPlayerValue frame(int ms, {bool playing = true}) => VideoPlayerValue(
  duration: const Duration(seconds: 20),
  position: Duration(milliseconds: ms),
  size: const Size(1080, 1920),
  isInitialized: true,
  isPlaying: playing,
);

void main() {
  test(
    'periodic reports include only true progress and dispose cancels sampling',
    () {
      fakeAsync((time) {
        final sent = <int>[];
        final measurement = ShortformPlaybackMeasurement(
          elapsed: () => time.elapsed,
          reporter: ShortformPlaybackReporter(
            eligible: () => true,
            elapsed: () => time.elapsed,
            send: (ms) async {
              sent.add(ms);
            },
          ),
        );
        measurement.setForeground(true);
        measurement.sample(frame(0));
        for (var n = 1; n <= 10; n++) {
          time.elapse(const Duration(milliseconds: 500));
          measurement.sample(frame(n * 500));
        }
        // The 5s timer runs before the final position sample.
        expect(sent, [4000]);
        measurement.dispose();
        time.elapse(const Duration(seconds: 1));
        expect(sent, [4000, 4500]);
        measurement.sample(frame(10000));
        time.elapse(const Duration(minutes: 1));
        expect(sent, [4000, 4500]);
        expect(time.periodicTimerCount, 0);
        expect(time.nonPeriodicTimerCount, 0);
      });
    },
  );

  test('foreground transitions flush without crediting the background gap', () {
    fakeAsync((time) {
      final sent = <int>[];
      final measurement = ShortformPlaybackMeasurement(
        elapsed: () => time.elapsed,
        reporter: ShortformPlaybackReporter(
          eligible: () => true,
          elapsed: () => time.elapsed,
          send: (ms) async {
            sent.add(ms);
          },
        ),
      );
      measurement.setForeground(true);
      measurement.sample(frame(500));
      time.elapse(const Duration(milliseconds: 500));
      measurement.sample(frame(1000));
      measurement.setForeground(false);
      time.flushMicrotasks();
      expect(sent, [500]);
      time.elapse(const Duration(seconds: 1));
      measurement.sample(frame(10000));
      measurement.setForeground(true);
      measurement.sample(frame(10500));
      time.elapse(const Duration(milliseconds: 500));
      measurement.sample(frame(11000));
      measurement.dispose();
      time.flushMicrotasks();
      expect(sent, [500, 1000]);
      expect(time.periodicTimerCount, 0);
    });
  });

  test('revocation stops both sampling and future reports', () {
    fakeAsync((time) {
      var allowed = true;
      final sent = <int>[];
      final measurement = ShortformPlaybackMeasurement(
        elapsed: () => time.elapsed,
        reporter: ShortformPlaybackReporter(
          eligible: () => allowed,
          elapsed: () => time.elapsed,
          send: (ms) async {
            sent.add(ms);
          },
        ),
      );
      measurement.setForeground(true);
      measurement.sample(frame(500));
      time.elapse(const Duration(milliseconds: 500));
      measurement.sample(frame(1000));
      allowed = false;
      measurement.sample(frame(1500));
      measurement.dispose();
      time.elapse(const Duration(minutes: 1));
      expect(sent, isEmpty);
      expect(time.periodicTimerCount, 0);
      expect(time.nonPeriodicTimerCount, 0);
    });
  });

  late VideoPlayerPlatform original;
  setUp(() {
    initTestColors();
    original = VideoPlayerPlatform.instance;
  });
  tearDown(() {
    VideoPlayerPlatform.instance = original;
  });

  Future<void> mount(
    WidgetTester tester,
    AdShortformFullscreenPage page,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final restore = suppressImageErrors();
    try {
      await tester.pumpWidget(buildTestAppPage(page));
      await tester.pump();
      await tester.pump();
      await tester.pump();
    } finally {
      restore();
    }
  }

  testWidgets('real route wires issued measurement, lifecycle and disposal', (
    tester,
  ) async {
    VideoPlayerPlatform.instance = _PlaybackPlatform();
    final sent = <int>[];
    var now = Duration.zero;
    var issued = false;
    await mount(
      tester,
      AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: _response,
        loadAd: () async {
          issued = true;
          return (
            videoUrl: 'https://example.com/ad.mp4',
            ctaUrl: null,
            blocked: false,
          );
        },
        createPlaybackMeasurement: () async {
          expect(issued, true);
          return ShortformPlaybackMeasurement(
            elapsed: () => now,
            reporter: ShortformPlaybackReporter(
              eligible: () => true,
              elapsed: () => now,
              send: (ms) async {
                sent.add(ms);
              },
            ),
          );
        },
      ),
    );
    final controller = tester
        .widget<VideoPlayer>(find.byType(VideoPlayer))
        .controller;
    void advance(int pos) {
      now += const Duration(milliseconds: 500);
      controller.value = frame(pos);
    }

    advance(500);
    advance(1000);
    advance(1500);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(sent, [1000]);
    advance(10000);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    advance(10500);
    advance(11000);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(sent, [1000, 1500]);
  });

  testWidgets(
    'a stalled analytics request does not delay the existing reward callback',
    (tester) async {
      VideoPlayerPlatform.instance = _PlaybackPlatform();
      var rewards = 0;
      var now = Duration.zero;
      final request = Completer<void>();
      final sent = <int>[];
      await mount(
        tester,
        AdShortformFullscreenPage(
          videoUrl: 'https://example.com/ad.mp4',
          onViewComplete: () {
            rewards++;
            return _response();
          },
          createPlaybackMeasurement: () async => ShortformPlaybackMeasurement(
            elapsed: () => now,
            reporter: ShortformPlaybackReporter(
              eligible: () => true,
              elapsed: () => now,
              send: (ms) {
                sent.add(ms);
                return request.future;
              },
            ),
          ),
        ),
      );
      final controller = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      now = const Duration(milliseconds: 500);
      controller.value = frame(500);
      now = const Duration(milliseconds: 1000);
      controller.value = frame(1000);
      now = const Duration(milliseconds: 1500);
      controller.value = frame(20000, playing: false);
      await tester.pump();
      expect(sent, [500]);
      expect(request.isCompleted, false);
      expect(rewards, 1);
      request.complete();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(rewards, 1);
    },
  );

  testWidgets(
    'route replaces measurements and discards overlapping late attachments',
    (tester) async {
      VideoPlayerPlatform.instance = _PlaybackPlatform();
      final initial = _TrackedMeasurement();
      final oldPending = Completer<ShortformPlaybackMeasurement?>();
      final newestPending = Completer<ShortformPlaybackMeasurement?>();
      final afterClose = Completer<ShortformPlaybackMeasurement?>();
      AdShortformFullscreenPage page(
        Future<ShortformPlaybackMeasurement?> Function() create,
      ) => AdShortformFullscreenPage(
        videoUrl: 'https://example.com/ad.mp4',
        onViewComplete: _response,
        createPlaybackMeasurement: create,
      );
      await mount(tester, page(() async => initial));
      expect(initial.disposals, 0);
      await tester.pumpWidget(buildTestAppPage(page(() => oldPending.future)));
      await tester.pump();
      expect(initial.disposals, 1);
      await tester.pumpWidget(
        buildTestAppPage(page(() => newestPending.future)),
      );
      await tester.pump();
      final newest = _TrackedMeasurement();
      newestPending.complete(newest);
      await tester.pump();
      final stale = _TrackedMeasurement();
      oldPending.complete(stale);
      await tester.pump();
      expect(stale.disposals, 1);
      expect(newest.disposals, 0);
      await tester.pumpWidget(buildTestAppPage(page(() => afterClose.future)));
      await tester.pump();
      expect(newest.disposals, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      final late = _TrackedMeasurement();
      afterClose.complete(late);
      await tester.pump();
      expect(late.disposals, 1);
    },
  );

  for (final revokeConsent in [true, false]) {
    testWidgets(
      'real route stops on ${revokeConsent ? 'consent withdrawal' : 'account switch'}',
      (tester) async {
        VideoPlayerPlatform.instance = _PlaybackPlatform();
        var owner = 'owner-a';
        var allowed = true;
        var now = Duration.zero;
        final sent = <Map<String, dynamic>>[];
        await mount(
          tester,
          AdShortformFullscreenPage(
            videoUrl: 'https://example.com/ad.mp4',
            onViewComplete: _response,
            createPlaybackMeasurement: () async => ShortformPlaybackMeasurement(
              elapsed: () => now,
              reporter: ShortformPlaybackReporter.forImpression(
                impressionId: '00000000-0000-4000-8000-000000000402',
                ownerUserId: 'owner-a',
                currentOwner: () => owner,
                hasConsent: () => allowed,
                invoke: (_, params) async {
                  sent.add(params);
                },
              ),
            ),
          ),
        );
        final controller = tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller;
        now = const Duration(milliseconds: 500);
        controller.value = frame(500);
        now = const Duration(milliseconds: 1000);
        controller.value = frame(1000);
        if (revokeConsent) {
          allowed = false;
        } else {
          owner = 'owner-b';
        }
        now = const Duration(milliseconds: 1500);
        controller.value = frame(1500);
        await tester.pump(const Duration(seconds: 6));
        // Returning to the old account or re-enabling consent must not revive
        // the stopped measurement for this impression.
        allowed = true;
        owner = 'owner-a';
        now = const Duration(milliseconds: 2000);
        controller.value = frame(2000);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 6));
        expect(sent, isEmpty);
      },
    );
  }
}

class _TrackedMeasurement extends ShortformPlaybackMeasurement {
  _TrackedMeasurement()
    : super(
        reporter: ShortformPlaybackReporter(
          eligible: () => true,
          send: (_) async {},
        ),
      );
  int disposals = 0;
  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

Future<InternalShortformViewResponse> _response() async =>
    const InternalShortformViewResponse(
      ok: false,
      rewardAdded: 0,
      impressionId: '00000000-0000-4000-8000-000000000402',
      newBonus: null,
    );

class _PlaybackPlatform extends VideoPlayerPlatform {
  late final StreamController<VideoEvent> _events =
      StreamController<VideoEvent>(
        onListen: () {
          scheduleMicrotask(() {
            _events.add(
              VideoEvent(
                eventType: VideoEventType.initialized,
                duration: const Duration(seconds: 20),
                size: const Size(1080, 1920),
                rotationCorrection: 0,
              ),
            );
          });
        },
        onCancel: () async {},
      );
  @override
  Future<void> init() async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<int?> create(DataSource dataSource) async => 19;
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 19;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Widget buildView(int playerId) => const SizedBox.shrink();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}
