import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

/// Writes the wallet summary a verified purchase came back with.
///
/// A named type rather than a bare `void Function(WalletSummaryModel)` because
/// `PurchaseSettlementStep` applies the wallet *whether or not the store is
/// still mounted* - the candy was granted server-side the moment the receipt
/// verified, so skipping the write leaves `walletSummaryProvider` on the
/// pre-purchase balance. `ConsumerState.ref` throws (`This widget has been
/// unmounted, so the State no longer has a context`) as soon as `mounted` is
/// false, so a closure over `ref` cannot satisfy that invariant. Requiring this
/// type at the call site is what stops one being passed.
abstract interface class WalletSummaryApplier {
  void call(WalletSummaryModel wallet);
}

/// Re-reads the wallet from the server.
///
/// The companion of [WalletSummaryApplier] for the settlements that arrive
/// *without* a balance to apply: a duplicate the server reports as
/// grant-confirmed carries only the verdict, not the amounts, yet the candy is
/// already credited. Applying nothing would leave the displayed balance on the
/// pre-purchase value until something else happened to refresh it.
///
/// Same container-not-`ref` rule as [WalletSummaryApplier], for the same
/// reason: this runs on the far side of receipt verification, which the user is
/// free to walk out on.
abstract interface class WalletSummaryRefresher {
  Future<void> refresh();
}

/// The production refresher: it re-reads through the [ProviderContainer],
/// captured while the store was still mounted.
final class ContainerWalletSummaryRefresher implements WalletSummaryRefresher {
  ContainerWalletSummaryRefresher.of(BuildContext context)
    : this.forContainer(ProviderScope.containerOf(context, listen: false));

  const ContainerWalletSummaryRefresher.forContainer(this._container);

  final ProviderContainer _container;

  @override
  Future<void> refresh() =>
      _container.read(walletSummaryProvider.notifier).refresh();
}

/// The production applier: it writes through the [ProviderContainer], captured
/// while the store was still mounted.
///
/// Same move as `voting_dialog.dart`'s post-failure wallet refresh
/// (PICNIC-APP-530), for the same reason: the container belongs to the
/// app-level `ProviderScope`, so it outlives the store route the user just
/// walked out of, while the `State` that reached it does not.
///
/// The capture has to happen up front - holding the [BuildContext] and looking
/// the container up on demand is the same bug, because the lookup itself needs
/// a live element.
final class ContainerWalletSummaryApplier implements WalletSummaryApplier {
  /// Captures the container behind [context]. Call this while the widget that
  /// owns [context] is mounted - `initState` is the natural place.
  ContainerWalletSummaryApplier.of(BuildContext context)
    : this.forContainer(ProviderScope.containerOf(context, listen: false));

  const ContainerWalletSummaryApplier.forContainer(this._container);

  final ProviderContainer _container;

  @override
  void call(WalletSummaryModel wallet) =>
      _container.read(walletSummaryProvider.notifier).setSummary(wallet);
}
