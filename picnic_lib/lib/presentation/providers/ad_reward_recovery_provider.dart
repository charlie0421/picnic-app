import 'dart:async';

import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/ad_reward_recovery_provider.g.dart';

/// Foreground ladder used right after the user finishes watching an ad, while
/// the server-side grant callback lands. Six reads spread over 30 seconds.
const adRewardPollDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
];

/// Startup/resume reconciliation replays the same bounded ladder, silently.
///
/// The sweep must keep rechecking: a reference recovered as PENDING can be
/// granted by the server seconds later, and if nobody re-reads it while the app
/// stays in the foreground the user is never told about a reward that has
/// already been paid out, and the acknowledgement that clears it is deferred to
/// the next launch. So the window stays as wide as [adRewardPollDelays].
///
/// What the sweep does *not* do is raise `checkingReferences`. That set drives
/// the "보상을 확인하고 있어요" banner, and because a reference the server never
/// resolves is never removed from `pending_ad_rewards_v1` (only a successful
/// acknowledgement deletes it), letting the sweep own the banner re-armed the
/// full 30 seconds of it on every cold start and every foreground. The wait is
/// the right behaviour; showing it for a wait the user did not trigger is not.
const adRewardRecoveryPollDelays = adRewardPollDelays;

typedef AdRewardDelay = Future<void> Function(Duration duration);
typedef AdRewardOwnerReader = String? Function();

@Riverpod(keepAlive: true)
AdRewardDelay adRewardDelay(Ref ref) => Future<void>.delayed;

@Riverpod(keepAlive: true)
AdRewardOwnerReader adRewardOwnerReader(Ref ref) =>
    () => supabase.auth.currentUser?.id;

class OwnedAdRewardStatus {
  const OwnedAdRewardStatus({
    required this.ownerUserId,
    required this.status,
    required this.generation,
  });

  final String ownerUserId;
  final AdRewardStatusModel status;
  final int generation;
}

class AdRewardRecoveryState {
  const AdRewardRecoveryState({
    this.activeUserId,
    this.references = const [],
    this.dialogQueue = const [],
    this.checkingReferences = const {},
  });

  final String? activeUserId;
  final List<AdRewardReference> references;
  final List<OwnedAdRewardStatus> dialogQueue;
  final Set<AdRewardReference> checkingReferences;

  AdRewardRecoveryState copyWith({
    List<AdRewardReference>? references,
    List<OwnedAdRewardStatus>? dialogQueue,
    Set<AdRewardReference>? checkingReferences,
  }) => AdRewardRecoveryState(
    activeUserId: activeUserId,
    references: references ?? this.references,
    dialogQueue: dialogQueue ?? this.dialogQueue,
    checkingReferences: checkingReferences ?? this.checkingReferences,
  );
}

@Riverpod(keepAlive: true)
class AdRewardRecovery extends _$AdRewardRecovery {
  final _polling = <String>{};
  final _acknowledging = <String>{};

  /// Claims a reference for the dialog pipeline, from the moment a terminal
  /// status is queued until the reference leaves that pipeline for good.
  ///
  /// The claim deliberately outlives the `dialogQueue` entry. Background and
  /// foreground ladders run side by side on one reference (see [_pollForOwner]),
  /// so a sibling poller can still be walking its 30 seconds of delays while the
  /// first poller's terminal status is already on screen. Releasing the claim
  /// when the dialog is acknowledged would let that late sibling re-read the
  /// same GRANTED status and queue it a second time - a second dialog and a
  /// second `acknowledge` for one reward. Only [discardDialog] releases it,
  /// because that is the one path where nothing was acknowledged and the
  /// reference genuinely has to be recoverable again.
  final _queued = <String>{};
  var _generation = 0;

  @override
  AdRewardRecoveryState build() => const AdRewardRecoveryState();

  String _key(String ownerUserId, AdRewardReference value) =>
      '$ownerUserId:${value.type.wireValue}:${value.id}';

  bool _isCurrent(String ownerUserId, int generation) =>
      generation == _generation &&
      state.activeUserId == ownerUserId &&
      ref.read(adRewardOwnerReaderProvider)() == ownerUserId;

  int _activateUser(String ownerUserId) {
    if (state.activeUserId != ownerUserId) {
      _generation++;
      _polling.clear();
      _acknowledging.clear();
      _queued.clear();
      state = AdRewardRecoveryState(activeUserId: ownerUserId);
    }
    return _generation;
  }

  void resetForLogout() {
    _generation++;
    _polling.clear();
    _acknowledging.clear();
    _queued.clear();
    state = const AdRewardRecoveryState();
  }

  Future<void> recover(String ownerUserId) async {
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) return;
    final generation = _activateUser(ownerUserId);
    final store = ref.read(pendingAdRewardStoreProvider);
    final repository = ref.read(adRewardRepositoryProvider);
    final localRecords = await store.readAll(ownerUserId);
    if (!_isCurrent(ownerUserId, generation)) return;

    final ackPending = localRecords
        .where((value) => value.state == PendingAdRewardLocalState.ackPending)
        .toList(growable: false);
    final ackPendingKeys = {
      for (final value in ackPending) _key(ownerUserId, value.reference),
    };
    for (final value in ackPending) {
      unawaited(
        _resumeAcknowledgement(ownerUserId, value.reference, generation),
      );
    }

    final serverItems = <AdRewardStatusModel>[];
    String? cursor;
    do {
      final page = await repository.listUnacknowledged(cursor: cursor);
      if (!_isCurrent(ownerUserId, generation)) return;
      serverItems.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);

    final unique = <String, AdRewardReference>{
      for (final value in localRecords)
        if (value.state == PendingAdRewardLocalState.pendingDisplay)
          _key(ownerUserId, value.reference): value.reference,
      for (final value in serverItems)
        if (!ackPendingKeys.contains(_key(ownerUserId, value.reference)))
          _key(ownerUserId, value.reference): value.reference,
    };
    if (!_isCurrent(ownerUserId, generation)) return;
    state = state.copyWith(references: unique.values.toList(growable: false));
    await Future.wait<void>([
      for (final reference in unique.values)
        _pollForOwner(ownerUserId, reference, generation, interactive: false),
    ]);
  }

  Future<void> poll({
    required String ownerUserId,
    required AdRewardReference reference,
  }) async {
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) return;
    final generation = _activateUser(ownerUserId);
    final key = _key(ownerUserId, reference);
    if (!state.references.any((value) => _key(ownerUserId, value) == key)) {
      state = state.copyWith(references: [...state.references, reference]);
    }
    await _pollForOwner(ownerUserId, reference, generation, interactive: true);
  }

  Future<void> _resumeAcknowledgement(
    String ownerUserId,
    AdRewardReference reference,
    int generation,
  ) async {
    if (!_isCurrent(ownerUserId, generation)) return;
    final token = '$generation:${_key(ownerUserId, reference)}';
    if (!_acknowledging.add(token)) return;
    try {
      await ref.read(adRewardRepositoryProvider).acknowledge(reference);
      if (!_isCurrent(ownerUserId, generation)) return;
      await ref
          .read(pendingAdRewardStoreProvider)
          .remove(ownerUserId, reference);
    } catch (_) {
      // Keep the ACK_PENDING tombstone. A later startup/resume retries it.
    } finally {
      _acknowledging.remove(token);
    }
  }

  /// Drops [reference] from the "checking your reward" set.
  ///
  /// Deliberately weaker than [_isCurrent]: it does not consult the auth
  /// reader. That set is progress UI only - never a payout input - so a
  /// transient `currentUser == null` (a token refresh landing mid-poll) must
  /// not be able to pin the banner on screen for the rest of the session.
  /// The generation and owner checks still keep one owner's teardown from
  /// touching another owner's state.
  void _stopChecking(
    String ownerUserId,
    AdRewardReference reference,
    int generation,
  ) {
    if (generation != _generation || state.activeUserId != ownerUserId) return;
    if (!state.checkingReferences.contains(reference)) return;
    state = state.copyWith(
      checkingReferences: {
        for (final value in state.checkingReferences)
          if (value != reference) value,
      },
    );
  }

  Future<void> _pollForOwner(
    String ownerUserId,
    AdRewardReference reference,
    int generation, {
    required bool interactive,
  }) async {
    if (!_isCurrent(ownerUserId, generation)) return;
    final key = _key(ownerUserId, reference);
    // The mode is part of the token so a background sweep already in flight
    // cannot swallow the foreground poll the user is actually waiting on.
    // Duplicate `get_ad_reward_status` reads are harmless; `_queued` admits the
    // reference to the dialog queue exactly once and holds that claim across
    // the acknowledgement, so the slower ladder cannot re-queue behind it.
    final pollToken = '$generation:${interactive ? 'fg' : 'bg'}:$key';
    if (!_polling.add(pollToken)) return;
    final delays = interactive
        ? adRewardPollDelays
        : adRewardRecoveryPollDelays;
    if (interactive) {
      state = state.copyWith(
        checkingReferences: {...state.checkingReferences, reference},
      );
    }
    try {
      final repository = ref.read(adRewardRepositoryProvider);
      for (var attempt = 0; attempt <= delays.length; attempt++) {
        final status = await repository.getStatus(reference);
        if (!_isCurrent(ownerUserId, generation)) return;
        if (status.reference != reference) {
          throw const FormatException('Ad reward status reference mismatch');
        }
        if (status.state != AdRewardState.pending) {
          if (_queued.add(key)) {
            state = state.copyWith(
              dialogQueue: [
                ...state.dialogQueue,
                OwnedAdRewardStatus(
                  ownerUserId: ownerUserId,
                  status: status,
                  generation: generation,
                ),
              ],
            );
          }
          return;
        }
        if (attempt < delays.length) {
          await ref.read(adRewardDelayProvider)(delays[attempt]);
          if (!_isCurrent(ownerUserId, generation)) return;
        }
      }
    } finally {
      _polling.remove(pollToken);
      if (interactive) _stopChecking(ownerUserId, reference, generation);
    }
  }

  /// Drops [queued] from the in-memory dialog queue after its first-frame
  /// acknowledgement failed, so a failed ACK can never re-present the same
  /// dialog. The durable record is left untouched: a genuinely un-acknowledged
  /// reward is re-polled and re-queued by the next recovery attempt.
  ///
  /// This is the only place the [_queued] claim is released, and it is only
  /// reachable before [acknowledgeAfterRender] persisted its tombstone - so
  /// nothing was acknowledged and re-arming the reference is the point.
  void discardDialog(OwnedAdRewardStatus queued) {
    final ownerUserId = queued.ownerUserId;
    final generation = queued.generation;
    if (!_isCurrent(ownerUserId, generation)) return;
    final key = _key(ownerUserId, queued.status.reference);
    if (state.dialogQueue.isEmpty ||
        state.dialogQueue.first.generation != generation ||
        _key(
              state.dialogQueue.first.ownerUserId,
              state.dialogQueue.first.status.reference,
            ) !=
            key) {
      return;
    }
    _queued.remove(key);
    state = state.copyWith(
      dialogQueue: state.dialogQueue
          .where(
            (value) => _key(value.ownerUserId, value.status.reference) != key,
          )
          .toList(growable: false),
    );
  }

  Future<void> acknowledgeAfterRender(OwnedAdRewardStatus queued) async {
    final ownerUserId = queued.ownerUserId;
    final status = queued.status;
    final generation = queued.generation;
    if (status.state == AdRewardState.pending) {
      throw StateError('Pending rewards cannot be acknowledged');
    }
    final key = _key(ownerUserId, status.reference);
    if (!_isCurrent(ownerUserId, generation)) {
      throw StateError('Ad reward owner is no longer active');
    }
    if (state.dialogQueue.isEmpty ||
        state.dialogQueue.first.generation != generation ||
        _key(
              state.dialogQueue.first.ownerUserId,
              state.dialogQueue.first.status.reference,
            ) !=
            key) {
      throw StateError('Ad reward is no longer the active dialog');
    }

    // Persisting the tombstone and calling `acknowledge` is one critical
    // section per reference: `acknowledge` is a payout input, not progress UI,
    // so two runs racing here would spend the same reward twice.
    final ackToken = '$generation:$key';
    if (!_acknowledging.add(ackToken)) return;
    try {
      final store = ref.read(pendingAdRewardStoreProvider);
      await store.markAckPending(ownerUserId, status.reference);
      if (!_isCurrent(ownerUserId, generation)) {
        throw StateError('Ad reward owner is no longer active');
      }
      // `_queued` is intentionally *not* released here. See its declaration:
      // dropping the claim now is what let a sibling ladder re-queue the same
      // reference while this acknowledgement was still in flight.
      state = state.copyWith(
        references: state.references
            .where((value) => _key(ownerUserId, value) != key)
            .toList(growable: false),
        dialogQueue: state.dialogQueue
            .where(
              (value) => _key(value.ownerUserId, value.status.reference) != key,
            )
            .toList(growable: false),
      );
      try {
        await ref
            .read(adRewardRepositoryProvider)
            .acknowledge(status.reference);
        if (!_isCurrent(ownerUserId, generation)) return;
        await store.remove(ownerUserId, status.reference);
      } catch (_) {
        // The durable ACK_PENDING tombstone prevents redisplay and is retried.
      }
    } finally {
      _acknowledging.remove(ackToken);
    }
  }
}
