import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_tracker.dart';

void main() {
  late ShortformPlaybackTracker tracker;
  var now = Duration.zero;

  void sample(
    int position, {
    bool playing = true,
    bool buffering = false,
    bool foreground = true,
    bool initialized = true,
    int elapsed = 500,
    int duration = 20000,
  }) {
    now += Duration(milliseconds: elapsed);
    tracker.sample(
      position: Duration(milliseconds: position),
      duration: Duration(milliseconds: duration),
      elapsed: now,
      isPlaying: playing,
      isBuffering: buffering,
      isInitialized: initialized,
      isForeground: foreground,
    );
  }

  setUp(() {
    tracker = ShortformPlaybackTracker();
    now = Duration.zero;
  });

  test('counts only progress after the first positive playing position', () {
    sample(0);
    sample(500);
    sample(1000);
    sample(1500);
    expect(tracker.watchedMs, 1000);
  });
  test('bounds each valid interval by monotonic elapsed time', () {
    sample(500);
    sample(1100);
    sample(1700);
    expect(tracker.watchedMs, 1000);
  });
  test('loading buffering pauses and background reset the baseline', () {
    sample(500, initialized: false);
    sample(1000, buffering: true);
    sample(1500, playing: false);
    sample(2000, foreground: false);
    sample(2500);
    sample(3000);
    expect(tracker.watchedMs, 500);
  });
  test('a paused terminal position does not manufacture playback', () {
    sample(500);
    sample(1000);
    sample(20000, playing: false);
    expect(tracker.watchedMs, 500);
  });
  test('forward seeks are discarded and do not create an elapsed credit', () {
    sample(500);
    sample(1000);
    sample(10000);
    sample(10500);
    expect(tracker.watchedMs, 1000);
  });
  test(
    'backward seeks and replays cannot count previously passed positions',
    () {
      sample(500);
      sample(1000);
      sample(1500);
      sample(0);
      sample(500);
      sample(1000);
      sample(1500);
      sample(2000);
      expect(tracker.watchedMs, 1500);
    },
  );
  test('duplicate callbacks do not reset the progress clock', () {
    sample(500);
    sample(500, elapsed: 250);
    sample(1000, elapsed: 250);
    sample(1000, elapsed: 0);
    sample(1500);
    expect(tracker.watchedMs, 1000);
  });
  test('unobserved long gaps receive no playback credit', () {
    sample(500);
    sample(1000, elapsed: 10000);
    sample(1500);
    expect(tracker.watchedMs, 500);
  });
  test('source duration caps out-of-range position reports', () {
    sample(500, duration: 1000);
    sample(1000, duration: 1000);
    sample(1500, duration: 1000);
    sample(2000, duration: 1000);
    expect(tracker.watchedMs, 500);
  });
  test('foreground boundary invalidates an old playing interval', () {
    sample(500);
    sample(1000);
    tracker.interrupt();
    sample(1500);
    sample(2000);
    expect(tracker.watchedMs, 1000);
  });
}
