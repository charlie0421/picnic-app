import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/wallet_resume_refresher.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

WalletSummaryModel _summary(DateTime snapshotAt, {int star = 0}) =>
    WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.from(star),
      bonus: BigInt.zero,
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: snapshotAt,
    );

void main() {
  late String? currentUserId;
  late bool walletLoaded;
  late DateTime now;
  late List<WalletSummaryModel> applied;
  late int readCount;
  late Completer<WalletSummaryModel>? gate;
  late Object? readError;
  late WalletSummaryModel nextSummary;

  WalletResumeRefresher build() => WalletResumeRefresher(
    currentUserId: () => currentUserId,
    isWalletLoaded: () => walletLoaded,
    readSummary: () async {
      readCount++;
      final pending = gate;
      if (pending != null) return pending.future;
      final error = readError;
      if (error != null) throw error;
      return nextSummary;
    },
    applySummary: applied.add,
    clock: () => now,
  );

  setUp(() {
    currentUserId = 'user-a';
    walletLoaded = true;
    now = DateTime.utc(2026, 1, 1);
    applied = [];
    readCount = 0;
    gate = null;
    readError = null;
    nextSummary = _summary(DateTime.utc(2026, 1, 1, 0, 0, 1), star: 10);
  });

  test('a signed-in resume reads the balance once and applies it', () async {
    final refresher = build();

    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.refreshed);
    expect(readCount, 1);
    expect(applied.single.star, BigInt.from(10));
  });

  test('a signed-out resume never reads the balance', () async {
    currentUserId = null;
    final refresher = build();

    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.notSignedIn);
    expect(readCount, 0);
    expect(applied, isEmpty);
  });

  test('a wallet that was never loaded is not fetched on resume', () async {
    walletLoaded = false;
    final refresher = build();

    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.notLoaded);
    expect(readCount, 0);
  });

  test('a repeat resume inside sixty seconds does not re-read', () async {
    final refresher = build();
    await refresher.refreshOnResume();

    now = now.add(const Duration(seconds: 59));
    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.cooledDown);
    expect(readCount, 1);
  });

  test('a resume at exactly sixty seconds re-reads', () async {
    final refresher = build();
    await refresher.refreshOnResume();

    now = now.add(kWalletResumeRefreshCooldown);
    nextSummary = _summary(DateTime.utc(2026, 1, 1, 0, 1, 1), star: 11);
    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.refreshed);
    expect(readCount, 2);
  });

  test('a backward clock does not lock the refresher out', () async {
    final refresher = build();
    await refresher.refreshOnResume();

    now = now.subtract(const Duration(seconds: 5));
    nextSummary = _summary(DateTime.utc(2026, 1, 1, 0, 0, 2), star: 12);
    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.refreshed);
    expect(readCount, 2);
  });

  test('overlapping resumes are coalesced into one read', () async {
    final pending = Completer<WalletSummaryModel>();
    gate = pending;
    final refresher = build();

    final first = refresher.refreshOnResume();
    final second = refresher.refreshOnResume();
    gate = null;
    pending.complete(nextSummary);
    final outcomes = await Future.wait([first, second]);

    expect(readCount, 1);
    expect(outcomes, [
      WalletResumeRefreshOutcome.refreshed,
      WalletResumeRefreshOutcome.refreshed,
    ]);
    expect(applied, hasLength(1));
  });

  test(
    'a failed read keeps the displayed balance and allows an immediate retry',
    () async {
      readError = StateError('network down');
      final refresher = build();

      final failed = await refresher.refreshOnResume();
      expect(failed, WalletResumeRefreshOutcome.failed);
      expect(applied, isEmpty);

      readError = null;
      final retried = await refresher.refreshOnResume();

      expect(retried, WalletResumeRefreshOutcome.refreshed);
      expect(readCount, 2);
    },
  );

  test('the resume read reuses the shared six second balance limit', () {
    expect(kWalletResumeRefreshReadTimeout, kWalletSummaryReadTimeout);
    expect(kWalletSummaryReadTimeout, const Duration(seconds: 6));
  });

  test('a balance read that never answers is cut off', () async {
    // 완결되지 않는 postgrest 응답이 resume 갱신을 영원히 붙잡지 못한다.
    gate = Completer<WalletSummaryModel>();
    final refresher = WalletResumeRefresher(
      currentUserId: () => currentUserId,
      isWalletLoaded: () => walletLoaded,
      readSummary: () async {
        readCount++;
        return gate!.future;
      },
      applySummary: applied.add,
      clock: () => now,
      readTimeout: const Duration(milliseconds: 20),
    );

    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.failed);
    expect(applied, isEmpty);
  });

  test('a balance that arrives after a sign-out is discarded', () async {
    final pending = Completer<WalletSummaryModel>();
    gate = pending;
    final refresher = build();

    final outcome = refresher.refreshOnResume();
    currentUserId = null;
    pending.complete(nextSummary);

    expect(await outcome, WalletResumeRefreshOutcome.superseded);
    expect(applied, isEmpty);
  });

  test('a balance that arrives after an account switch is discarded', () async {
    final pending = Completer<WalletSummaryModel>();
    gate = pending;
    final refresher = build();

    final outcome = refresher.refreshOnResume();
    currentUserId = 'user-b';
    pending.complete(nextSummary);

    expect(await outcome, WalletResumeRefreshOutcome.superseded);
    expect(applied, isEmpty);
  });

  test('a balance in flight when reset() lands is discarded', () async {
    final pending = Completer<WalletSummaryModel>();
    gate = pending;
    final refresher = build();

    final outcome = refresher.refreshOnResume();
    refresher.reset();
    pending.complete(nextSummary);

    expect(await outcome, WalletResumeRefreshOutcome.superseded);
    expect(applied, isEmpty);
  });

  test('A to B to A does not reuse the first account cooldown', () async {
    final refresher = build();
    await refresher.refreshOnResume();
    expect(readCount, 1);

    currentUserId = 'user-b';
    refresher.reset();
    nextSummary = _summary(DateTime.utc(2026, 1, 1, 0, 0, 2), star: 20);
    await refresher.refreshOnResume();
    expect(readCount, 2);

    currentUserId = 'user-a';
    refresher.reset();
    nextSummary = _summary(DateTime.utc(2026, 1, 1, 0, 0, 3), star: 30);
    final outcome = await refresher.refreshOnResume();

    expect(outcome, WalletResumeRefreshOutcome.refreshed);
    expect(readCount, 3);
    expect(applied.last.star, BigInt.from(30));
  });
}
