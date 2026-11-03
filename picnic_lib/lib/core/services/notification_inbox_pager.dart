import 'dart:collection';

import 'package:picnic_lib/data/models/inbox_notification.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';

class NotificationCursor {
  const NotificationCursor({required this.createdAt, required this.id});

  final String createdAt;
  final int id;
}

abstract interface class NotificationInboxDataSource {
  String? get currentUserId;

  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  });

  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  });

  Future<List<int>> updatePersonalRead({required String userId, int? id});

  Future<int?> fetchBroadcastMaxId();

  Future<List<int>> fetchBroadcastIds({
    required int afterId,
    required int maxId,
    required int limit,
  });
}

class NotificationInboxPage {
  const NotificationInboxPage({required this.items, required this.hasMore});

  final List<InboxNotification> items;
  final bool hasMore;
}

class NotificationPageLoadException implements Exception {
  const NotificationPageLoadException();

  @override
  String toString() => 'NotificationPageLoadException';
}

class NotificationInboxPager {
  NotificationInboxPager({
    required NotificationInboxDataSource source,
    required BroadcastNotificationReadStore readStore,
    required this.accountId,
    this.sourcePageSize = 20,
  }) : _source = source,
       _readStore = readStore,
       _personalExhausted = accountId == null;

  final NotificationInboxDataSource _source;
  final BroadcastNotificationReadStore _readStore;
  final String? accountId;
  final int sourcePageSize;

  final ListQueue<InboxNotification> _personalBuffer = ListQueue();
  final ListQueue<InboxNotification> _broadcastBuffer = ListQueue();
  final Set<String> _emittedIdentities = {};
  NotificationCursor? _personalCursor;
  NotificationCursor? _broadcastCursor;
  late bool _personalExhausted;
  bool _broadcastExhausted = false;
  Set<int>? _broadcastReadIds;
  bool _hasMore = true;
  Future<NotificationInboxPage>? _inFlight;

  bool get hasMore => _hasMore;

  Set<int> snapshotBufferedPersonalIds() => _personalBuffer
      .where((item) => !item.isRead)
      .map((item) => item.id)
      .toSet();

  void applyReadIds({
    Iterable<int> personalIds = const [],
    Iterable<int> broadcastIds = const [],
  }) {
    final personal = personalIds.toSet();
    final broadcast = broadcastIds.toSet();
    _broadcastReadIds?.addAll(broadcast);
    _replaceReadItems(_personalBuffer, personal);
    _replaceReadItems(_broadcastBuffer, broadcast);
  }

  void _replaceReadItems(
    ListQueue<InboxNotification> buffer,
    Set<int> readIds,
  ) {
    if (readIds.isEmpty || buffer.isEmpty) return;
    final updated = buffer
        .map((item) => readIds.contains(item.id) ? item.markedRead() : item)
        .toList(growable: false);
    buffer
      ..clear()
      ..addAll(updated);
  }

  Future<NotificationInboxPage> nextPage({int limit = 20}) {
    final pending = _inFlight;
    if (pending != null) return pending;

    late final Future<NotificationInboxPage> tracked;
    tracked = _loadNextPage(limit: limit).whenComplete(() {
      if (identical(_inFlight, tracked)) _inFlight = null;
    });
    _inFlight = tracked;
    return tracked;
  }

  Future<NotificationInboxPage> _loadNextPage({required int limit}) async {
    if (!_hasMore || limit <= 0) {
      return const NotificationInboxPage(items: [], hasMore: false);
    }

    _broadcastReadIds ??= await _readStore.readIds(accountId);
    final output = <InboxNotification>[];

    try {
      while (output.length < limit) {
        await _replenishEmptyBuffers();
        if (_personalBuffer.isEmpty && _broadcastBuffer.isEmpty) {
          _hasMore = false;
          break;
        }

        final next = _takeNewestHead();
        if (_emittedIdentities.add(next.identity)) {
          output.add(next);
        }
      }
    } catch (_) {
      for (final notification in output.reversed) {
        _emittedIdentities.remove(notification.identity);
        final buffer = notification.source == NotificationSource.personal
            ? _personalBuffer
            : _broadcastBuffer;
        buffer.addFirst(notification);
      }
      rethrow;
    }

    _hasMore =
        !(_personalExhausted &&
            _broadcastExhausted &&
            _personalBuffer.isEmpty &&
            _broadcastBuffer.isEmpty);
    return NotificationInboxPage(items: output, hasMore: _hasMore);
  }

  Future<void> _replenishEmptyBuffers() async {
    Object? failure;

    if (_personalBuffer.isEmpty && !_personalExhausted) {
      try {
        final rows = await _source.fetchPersonal(
          userId: accountId!,
          cursor: _personalCursor,
          limit: sourcePageSize,
        );
        _acceptRows(NotificationSource.personal, rows);
      } catch (_) {
        failure = const NotificationPageLoadException();
      }
    }

    if (_broadcastBuffer.isEmpty && !_broadcastExhausted) {
      try {
        final rows = await _source.fetchBroadcast(
          cursor: _broadcastCursor,
          limit: sourcePageSize,
        );
        _acceptRows(NotificationSource.broadcast, rows);
      } catch (_) {
        failure = const NotificationPageLoadException();
      }
    }

    if (failure != null) throw failure;
  }

  void _acceptRows(
    NotificationSource notificationSource,
    List<UserNotification> rows,
  ) {
    final exhausted = rows.length < sourcePageSize;
    final buffer = notificationSource == NotificationSource.personal
        ? _personalBuffer
        : _broadcastBuffer;

    for (final notification in rows) {
      var inbox = InboxNotification(
        source: notificationSource,
        notification: notification,
      );
      if (notificationSource == NotificationSource.broadcast &&
          _broadcastReadIds!.contains(notification.id)) {
        inbox = inbox.markedRead();
      }
      buffer.add(inbox);
    }

    if (rows.isNotEmpty) {
      final last = rows.last;
      final cursor = NotificationCursor(
        createdAt: last.createdAt ?? '',
        id: last.id,
      );
      if (notificationSource == NotificationSource.personal) {
        _personalCursor = cursor;
      } else {
        _broadcastCursor = cursor;
      }
    }

    if (notificationSource == NotificationSource.personal) {
      _personalExhausted = exhausted;
    } else {
      _broadcastExhausted = exhausted;
    }
  }

  InboxNotification _takeNewestHead() {
    if (_personalBuffer.isEmpty) return _broadcastBuffer.removeFirst();
    if (_broadcastBuffer.isEmpty) return _personalBuffer.removeFirst();
    final personal = _personalBuffer.first;
    final broadcast = _broadcastBuffer.first;
    return _compare(personal, broadcast) <= 0
        ? _personalBuffer.removeFirst()
        : _broadcastBuffer.removeFirst();
  }

  int _compare(InboxNotification left, InboxNotification right) {
    final leftTime = DateTime.tryParse(left.createdAt ?? '');
    final rightTime = DateTime.tryParse(right.createdAt ?? '');
    if (leftTime != null && rightTime != null) {
      final timeComparison = rightTime.compareTo(leftTime);
      if (timeComparison != 0) return timeComparison;
    } else {
      final timeComparison = (right.createdAt ?? '').compareTo(
        left.createdAt ?? '',
      );
      if (timeComparison != 0) return timeComparison;
    }
    final idComparison = right.id.compareTo(left.id);
    if (idComparison != 0) return idComparison;
    return left.source.index.compareTo(right.source.index);
  }
}
