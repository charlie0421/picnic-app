import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';

final class PicnicImagePrefetchScope {
  PicnicImagePrefetchScope({int maximumCandidates = 2})
    : _maximumCandidates = _validateMaximumCandidates(maximumCandidates);

  final int _maximumCandidates;

  int _generation = 0;
  bool _disposed = false;
  Set<Object> _desiredKeys = const {};

  void replace(BuildContext context, Iterable<PicnicImageRequest> requests) {
    if (_disposed) return;
    final generation = ++_generation;
    _desiredKeys = const {};
    _prefetchScheduler.removeScope(this);
    if (!context.mounted) return;

    final configuration = createLocalImageConfiguration(context);
    unawaited(_resolveCandidates(context, configuration, requests, generation));
  }

  Future<void> _resolveCandidates(
    BuildContext context,
    ImageConfiguration configuration,
    Iterable<PicnicImageRequest> requests,
    int generation,
  ) async {
    final candidates = <Object, PicnicImageRequest>{};
    final iterator = requests.iterator;
    while (candidates.length < _maximumCandidates) {
      if (!_isCurrent(generation) || !context.mounted) return;
      try {
        if (!iterator.moveNext()) break;
      } on Object {
        break;
      }
      final request = iterator.current;
      if (request.url.trim().isEmpty) continue;
      Object key;
      try {
        key = await request.obtainKey(configuration);
      } on Object {
        continue;
      }
      if (!_isCurrent(generation) || !context.mounted) return;
      candidates.putIfAbsent(key, () => request);
    }

    if (!_isCurrent(generation) || !context.mounted) return;
    _desiredKeys = Set<Object>.unmodifiable(candidates.keys);
    _prefetchScheduler.addCandidates(this, generation, context, candidates);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _desiredKeys = const {};
    _prefetchScheduler.removeScope(this);
  }

  bool _isCurrent(int generation) => !_disposed && _generation == generation;

  bool _hasInterest(int generation, Object key, BuildContext context) {
    return _isCurrent(generation) &&
        _desiredKeys.contains(key) &&
        context.mounted;
  }

  static int _validateMaximumCandidates(int value) {
    if (value < 1 || value > 3) {
      throw RangeError.range(value, 1, 3, 'maximumCandidates');
    }
    return value;
  }
}

final _PicnicImagePrefetchScheduler _prefetchScheduler =
    _PicnicImagePrefetchScheduler();

final class _PicnicImagePrefetchScheduler {
  static const int _maximumActiveJobs = 2;

  final Queue<_PrefetchJob> _queue = ListQueue<_PrefetchJob>();
  final Map<Object, _PrefetchJob> _queuedByKey = {};
  final Map<Object, _PrefetchJob> _inFlightByKey = {};
  int _activeCount = 0;

  void addCandidates(
    PicnicImagePrefetchScope scope,
    int generation,
    BuildContext context,
    Map<Object, PicnicImageRequest> candidates,
  ) {
    if (!scope._isCurrent(generation) || !context.mounted) return;

    for (final entry in candidates.entries) {
      final interest = _PrefetchInterest(scope, generation, context, entry.key);
      final inFlight = _inFlightByKey[entry.key];
      if (inFlight != null) {
        inFlight.interests[scope] = interest;
        continue;
      }

      final queued = _queuedByKey[entry.key];
      if (queued != null) {
        queued.interests[scope] = interest;
        continue;
      }

      if (PaintingBinding.instance.imageCache.statusForKey(entry.key).tracked) {
        continue;
      }

      final job = _PrefetchJob(entry.key, entry.value)
        ..interests[scope] = interest;
      _queuedByKey[entry.key] = job;
      _queue.add(job);
    }
    _drain();
  }

  void removeScope(PicnicImagePrefetchScope scope) {
    for (final job in _queuedByKey.values.toList(growable: false)) {
      job.interests.remove(scope);
      if (job.interests.isEmpty) {
        _queuedByKey.remove(job.key);
        _queue.remove(job);
      }
    }
    for (final job in _inFlightByKey.values) {
      job.interests.remove(scope);
    }
    _drain();
  }

  void _drain() {
    while (_activeCount < _maximumActiveJobs && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      if (!identical(_queuedByKey[job.key], job)) continue;

      job.interests.removeWhere((_, interest) => !interest.isCurrent);
      if (job.interests.isEmpty) {
        _queuedByKey.remove(job.key);
        continue;
      }

      if (PaintingBinding.instance.imageCache.statusForKey(job.key).tracked) {
        _queuedByKey.remove(job.key);
        continue;
      }

      final context = job.interests.values.first.context;
      if (!context.mounted) {
        _queuedByKey.remove(job.key);
        continue;
      }

      _queuedByKey.remove(job.key);
      _inFlightByKey[job.key] = job;
      _activeCount++;
      unawaited(_run(job, context));
    }
  }

  Future<void> _run(_PrefetchJob job, BuildContext context) async {
    try {
      if (!context.mounted) return;
      await precacheImage(
        job.request.provider,
        context,
        onError: (Object _, StackTrace? _) {
          PaintingBinding.instance.imageCache.evict(job.key, includeLive: true);
        },
      );
    } on Object {
      PaintingBinding.instance.imageCache.evict(job.key, includeLive: true);
    } finally {
      if (identical(_inFlightByKey[job.key], job)) {
        _inFlightByKey.remove(job.key);
      }
      _activeCount--;
      _drain();
    }
  }
}

final class _PrefetchJob {
  _PrefetchJob(this.key, this.request);

  final Object key;
  final PicnicImageRequest request;
  final Map<PicnicImagePrefetchScope, _PrefetchInterest> interests = {};
}

final class _PrefetchInterest {
  const _PrefetchInterest(this.scope, this.generation, this.context, this.key);

  final PicnicImagePrefetchScope scope;
  final int generation;
  final BuildContext context;
  final Object key;

  bool get isCurrent => scope._hasInterest(generation, key, context);
}
