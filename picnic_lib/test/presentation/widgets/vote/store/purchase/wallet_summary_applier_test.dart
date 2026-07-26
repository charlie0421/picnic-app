import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';

/// Stands in for the store: a `ConsumerState` that captures the applier in
/// `initState`, exactly where `PurchaseStarCandyState` captures it.
///
/// It also hands its own `ref` back, so the test can show what the settlement
/// call site used to do and why it could not work.
class _StoreStandIn extends ConsumerStatefulWidget {
  const _StoreStandIn({required this.onInit});

  final void Function(_StoreStandInState state) onInit;

  @override
  ConsumerState<_StoreStandIn> createState() => _StoreStandInState();
}

class _StoreStandInState extends ConsumerState<_StoreStandIn> {
  late final WalletSummaryApplier applier;

  @override
  void initState() {
    super.initState();
    applier = ContainerWalletSummaryApplier.of(context);
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The seam that lets a settled purchase credit the wallet after the user has
/// walked out of the store.
///
/// Receipt verification outlives the route: the user taps buy, backs out, and
/// the verified result lands on a `State` that is already gone. The candy was
/// granted server-side the moment the receipt verified, so
/// `PurchaseSettlementStep` applies the wallet whether or not the store is
/// still mounted - and the only way to honour that is to write through
/// something that is not the widget.
void main() {
  final settled = WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.from(100),
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026),
  );

  /// A container whose wallet never resolves on its own, so the only thing
  /// that can put a value in it is the applier under test.
  ProviderContainer containerWithPendingWallet() {
    final container = ProviderContainer(
      overrides: [
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) => Completer<WalletSummaryModel>().future,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<_StoreStandInState> mountStore(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    late _StoreStandInState state;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _StoreStandIn(onInit: (created) => state = created),
      ),
    );
    return state;
  }

  testWidgets('the wallet still lands after the store that captured it is '
      'gone', (tester) async {
    final container = containerWithPendingWallet();
    final store = await mountStore(tester, container);
    final applier = store.applier;

    // The user leaves the store while verification is still in flight.
    await tester.pumpWidget(const SizedBox());
    expect(store.mounted, isFalse);

    applier(settled);

    expect(
      container.read(walletSummaryProvider).value,
      same(settled),
      reason:
          'the candy is already granted server-side; dropping this write '
          'leaves walletSummaryProvider on the pre-purchase balance until the '
          'next refresh, with no error surfaced to the user',
    );
  });

  testWidgets('which the store\'s own ref cannot do', (tester) async {
    final container = containerWithPendingWallet();
    final store = await mountStore(tester, container);

    await tester.pumpWidget(const SizedBox());

    expect(
      () => store.ref.read(walletSummaryProvider.notifier).setSummary(settled),
      throwsA(anything),
      reason:
          'this is the read the settlement call site used to be given; it '
          'throws once the State is unmounted, which is why the applier '
          'captures the container up front instead',
    );
    expect(container.read(walletSummaryProvider).value, isNull);
  });

  testWidgets('holding the context instead of the container is the same bug', (
    tester,
  ) async {
    final container = containerWithPendingWallet();
    final store = await mountStore(tester, container);
    final context = store.context;

    await tester.pumpWidget(const SizedBox());

    expect(
      () => ProviderScope.containerOf(context, listen: false),
      throwsA(anything),
      reason:
          'the lookup itself needs a live element, so deferring it to call '
          'time defeats the capture',
    );
  });
}
