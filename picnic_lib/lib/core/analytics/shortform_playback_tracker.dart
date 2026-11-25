/// Conservative first-pass playback credit for one issued impression.
/// Initialization alone is not a frame: the first positive playing position
/// establishes the baseline and earns no credit. Replayed positions never earn
/// credit again. Missing observations and position discontinuities earn none.
class ShortformPlaybackTracker {
  int _watchedUs = 0;
  int _furthestUs = 0;
  int? _positionUs;
  int? _elapsedUs;

  int get watchedMs => _watchedUs ~/ Duration.microsecondsPerMillisecond;

  void interrupt() {
    _positionUs = null;
    _elapsedUs = null;
  }

  void sample({
    required Duration position,
    required Duration duration,
    required Duration elapsed,
    required bool isPlaying,
    required bool isBuffering,
    required bool isInitialized,
    required bool isForeground,
  }) {
    final end = duration.inMicroseconds;
    if (!isInitialized ||
        !isPlaying ||
        isBuffering ||
        !isForeground ||
        end <= 0 ||
        position <= Duration.zero) {
      interrupt();
      return;
    }
    final pos = position.inMicroseconds.clamp(0, end).toInt();
    final now = elapsed.inMicroseconds;
    final previous = _positionUs;
    final previousTime = _elapsedUs;
    // Repeated controller notifications for an unchanged position must not
    // consume the monotonic interval belonging to the next position update.
    if (pos == previous && previousTime != null && now >= previousTime) return;
    if (previous != null && previousTime != null) {
      final advance = pos - previous;
      final wall = now - previousTime;
      if (advance > 0 &&
          wall > 0 &&
          wall <= 2000000 &&
          advance <= wall + 250000) {
        final furthest = previous > _furthestUs ? previous : _furthestUs;
        final novel = pos > furthest ? pos - furthest : 0;
        final credit = novel < wall ? novel : wall;
        final total = _watchedUs + credit;
        _watchedUs = total < end ? total : end;
      }
    }
    if (pos > _furthestUs) _furthestUs = pos;
    _positionUs = pos;
    _elapsedUs = now;
  }
}
