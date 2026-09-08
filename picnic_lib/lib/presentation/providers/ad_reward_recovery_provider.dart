import 'dart:async';

import 'package:picnic_lib/core/analytics/ad_reward_earn_recorder.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/ad_reward_recovery_provider.g.dart';

/// Foreground ladder used right after the user finishes watching an ad, while
/// the server-side grant callback lands. Six reads spread over 30 seconds.
///
/// This is the **only** ladder left. Startup, resume and same-user auth events
/// used to replay it over every unacknowledged reward the server knew about,
/// which is what made a cold start cost one `list_unacknowledged_ad_rewards`
/// page walk plus six `get_ad_reward_status` reads per stale reference. The
/// current ad the user just watched is the one result worth waiting for; the
/// balance that past rewards moved is picked up by the resume balance read
/// (`WalletResumeRefresher`) instead.
const adRewardPollDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
];

typedef AdRewardDelay = Future<void> Function(Duration duration);
typedef AdRewardOwnerReader = String? Function();

/// Persists one confirmed grant to the durable analytics outbox.
///
/// A seam rather than a direct call so the recovery notifier can be tested
/// without a storage backend, and so the mapping from a reward status to a GA4
/// payload stays in `core/analytics` next to the outbox it feeds.
typedef AdRewardEarnRecorder =
    Future<bool> Function(AdRewardStatusModel status);

final adRewardEarnRecorderProvider = Provider<AdRewardEarnRecorder>(
  (ref) =>
      (status) => recordAdRewardEarn(status: status),
);

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

  /// References whose confirmed grant already reached the analytics outbox in
  /// this process. The durable outbox dedupes on its own key, so this is only
  /// here to keep a repeated callback for one ad from queueing redundant
  /// storage work. A failed write drops back out so a later confirmation of the
  /// same reward can try again.
  final _earnRecorded = <String>{};

  /// Claims a reference for the dialog pipeline, from the moment a terminal
  /// status is queued until the reference leaves that pipeline for good.
  ///
  /// The claim deliberately outlives the `dialogQueue` entry. Background and
  /// foreground ladders run side by side on one reference (see
  /// [_pollRecoveredReferences] and [_pollForegroundForOwner]), so a sibling
  /// poller can still be walking its 30 seconds of delays while the first
  /// poller's terminal status is already on screen. Releasing the claim when
  /// the dialog is acknowledged would let that late sibling re-read the same
  /// GRANTED status and queue it a second time - a second dialog and a second
  /// `acknowledge` for one reward. Only [discardDialog] releases it, because
  /// that is the one path where nothing was acknowledged and the reference
  /// genuinely has to be recoverable again.
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
      _earnRecorded.clear();
      _queued.clear();
      state = AdRewardRecoveryState(activeUserId: ownerUserId);
    }
    return _generation;
  }

  void resetForLogout() {
    _generation++;
    _polling.clear();
    _acknowledging.clear();
    _earnRecorded.clear();
    _queued.clear();
    state = const AdRewardRecoveryState();
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
    await _pollForegroundForOwner(ownerUserId, reference, generation);
  }

  /// Persists a confirmed grant to the durable analytics outbox, once.
  ///
  /// Deliberately not the dialog's job. `AdRewardDialogHost` used to send this
  /// right before it opened the receipt, so a grant the app had already
  /// confirmed went unrecorded whenever the host was not mounted or the user
  /// left the ad screen first - and the fullscreen shortform route, which
  /// presents its own receipt and never enters the dialog queue, recorded
  /// nothing at all. The grant is what the event describes, so the write
  /// belongs at the moment the grant is confirmed.
  ///
  /// Fire-and-forget on purpose: the outbox owns delivery and retry, and a
  /// storage hiccup must not stall the poll the user is waiting on.
  void _recordConfirmedEarn(String ownerUserId, AdRewardStatusModel status) {
    final grant = status.grant;
    if (status.state != AdRewardState.granted ||
        grant == null ||
        grant.amount <= BigInt.zero) {
      return;
    }
    final key = _key(ownerUserId, status.reference);
    if (!_earnRecorded.add(key)) return;
    unawaited(
      Future.sync(() => ref.read(adRewardEarnRecorderProvider)(status)).then(
        (stored) {
          if (!stored) _earnRecorded.remove(key);
        },
        onError: (Object error, StackTrace stackTrace) {
          _earnRecorded.remove(key);
          logger.e('적립 통계 저장 실패: $key', error: error, stackTrace: stackTrace);
        },
      ),
    );
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

  bool _validateAndQueueTerminalStatus(
    String ownerUserId,
    AdRewardReference reference,
    AdRewardStatusModel status,
    int generation,
  ) {
    if (status.reference != reference) {
      throw const FormatException('Ad reward status reference mismatch');
    }
    if (status.state == AdRewardState.pending) return false;

    _recordConfirmedEarn(ownerUserId, status);

    final key = _key(ownerUserId, reference);
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
    return true;
  }

  Future<void> _pollForegroundForOwner(
    String ownerUserId,
    AdRewardReference reference,
    int generation,
  ) async {
    if (!_isCurrent(ownerUserId, generation)) return;
    final key = _key(ownerUserId, reference);
    // One ladder per reference per generation. Duplicate `get_ad_reward_status`
    // reads are harmless; `_queued` admits the reference to the dialog queue
    // exactly once and holds that claim across the acknowledgement, so a second
    // callback for the same ad cannot produce a second receipt.
    final pollToken = '$generation:fg:$key';
    if (!_polling.add(pollToken)) return;
    state = state.copyWith(
      checkingReferences: {...state.checkingReferences, reference},
    );
    try {
      final repository = ref.read(adRewardRepositoryProvider);
      for (var attempt = 0; attempt <= adRewardPollDelays.length; attempt++) {
        final status = await repository.getStatus(reference);
        if (!_isCurrent(ownerUserId, generation)) return;
        if (_validateAndQueueTerminalStatus(
          ownerUserId,
          reference,
          status,
          generation,
        )) {
          return;
        }
        if (attempt < adRewardPollDelays.length) {
          await ref.read(adRewardDelayProvider)(adRewardPollDelays[attempt]);
          if (!_isCurrent(ownerUserId, generation)) return;
        }
      }
    } finally {
      _polling.remove(pollToken);
      _stopChecking(ownerUserId, reference, generation);
    }
  }

  /// Drops [queued] from the in-memory dialog queue after its first-frame
  /// acknowledgement failed, so a failed ACK can never re-present the same
  /// dialog. The durable record is left untouched - nothing was acknowledged,
  /// and the server reward and ledger entry are not this notifier's to discard.
  ///
  /// The reward itself is unaffected: the server already paid it, the balance
  /// is applied from the same confirmed snapshot, and the analytics outbox
  /// entry was written when the grant was confirmed. What is lost is only the
  /// receipt dialog for this one reference in this session.
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

    await _acknowledgeTerminal(
      ownerUserId: ownerUserId,
      status: status,
      generation: generation,
    );
  }

  /// The app observed a confirmed grant outside the polling path.
  ///
  /// The internal shortform view callback can come back already GRANTED, and on
  /// that path nothing else is guaranteed to run: the fullscreen route renders
  /// its receipt only while mounted, and [acknowledgePresented] runs from that
  /// receipt's first frame. Recording here makes the analytics entry depend on
  /// the grant rather than on the popup surviving.
  ///
  /// Silently ignored when the reward is not a positive grant or the owner is
  /// no longer signed in - statistics never interrupt an ad flow. Duplicates
  /// with the later [acknowledgePresented] are collapsed by the same reference
  /// key that the durable outbox uses.
  void recordConfirmedGrant({
    required String ownerUserId,
    required AdRewardStatusModel status,
  }) {
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) return;
    _activateUser(ownerUserId);
    _recordConfirmedEarn(ownerUserId, status);
  }

  /// A terminal reward was rendered by the fullscreen ad route itself, before
  /// it can enter the app-level dialog queue. Persist the same acknowledgement
  /// tombstone used by [acknowledgeAfterRender] so it cannot reappear later.
  ///
  /// This is also a point where the app confirms a grant, so the analytics
  /// outbox entry is written here too. It carries the same reference key as the
  /// polled path and as the legacy shortform response path, so a reward that
  /// reaches two of them is still counted once.
  Future<void> acknowledgePresented({
    required String ownerUserId,
    required AdRewardStatusModel status,
  }) async {
    if (status.state == AdRewardState.pending) {
      throw StateError('Pending rewards cannot be acknowledged');
    }
    if (ref.read(adRewardOwnerReaderProvider)() != ownerUserId) {
      throw StateError('Ad reward owner is no longer active');
    }
    final generation = _activateUser(ownerUserId);
    _recordConfirmedEarn(ownerUserId, status);
    await _acknowledgeTerminal(
      ownerUserId: ownerUserId,
      status: status,
      generation: generation,
    );
  }

  Future<void> _acknowledgeTerminal({
    required String ownerUserId,
    required AdRewardStatusModel status,
    required int generation,
  }) async {
    final key = _key(ownerUserId, status.reference);

    // Persisting the tombstone and calling `acknowledge` is one critical
    // section per reference. The RPC records display completion; it does not
    // pay the reward. Serializing it still prevents duplicate ACK traffic and
    // keeps the durable tombstone aligned with the in-memory queue.
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
