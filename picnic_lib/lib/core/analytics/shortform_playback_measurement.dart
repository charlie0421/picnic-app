import 'dart:async';

import 'package:picnic_lib/core/analytics/shortform_playback_reporter.dart';
import 'package:picnic_lib/core/analytics/shortform_playback_tracker.dart';
import 'package:video_player/video_player.dart';

/// Owns measurement resources for one route; never calls a reward API.
class ShortformPlaybackMeasurement {
  ShortformPlaybackMeasurement({
    required ShortformPlaybackReporter reporter,
    Duration Function()? elapsed,
  }) : _reporter = reporter {
    final watch = Stopwatch()..start();
    _elapsed = elapsed ?? (() => watch.elapsed);
    _periodic = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_reporter.canMeasure) {
        stop();
        return;
      }
      unawaited(_reporter.flush());
    });
  }

  final ShortformPlaybackReporter _reporter;
  final _tracker = ShortformPlaybackTracker();
  late final Duration Function() _elapsed;
  Timer? _periodic;
  bool _foreground = false;
  bool _active = false;
  bool _disposed = false;

  void setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    _active = false;
    _tracker.interrupt();
    if (!foreground) unawaited(_reporter.flush());
  }

  void sample(VideoPlayerValue value) {
    if (_disposed) return;
    if (!_reporter.canMeasure) {
      stop();
      return;
    }
    final active =
        _foreground &&
        value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError;
    _tracker.sample(
      position: value.position,
      duration: value.duration,
      elapsed: _elapsed(),
      isInitialized: value.isInitialized && !value.hasError,
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      isForeground: _foreground,
    );
    _reporter.update(_tracker.watchedMs);
    if ((_active && !active) ||
        (value.duration > Duration.zero && value.position >= value.duration)) {
      unawaited(_reporter.flush());
    }
    _active = active;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _periodic?.cancel();
    _periodic = null;
    _tracker.interrupt();
    unawaited(_reporter.close());
  }

  void stop() {
    if (_disposed) return;
    _disposed = true;
    _periodic?.cancel();
    _periodic = null;
    _tracker.interrupt();
    _reporter.stop();
  }
}
