import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';

/// The process-lifetime owner of purchase delivery.
///
/// A plain `Provider` on purpose: it is created from the app-level container, it
/// is never invalidated, and reading it twice must return the *same* object -
/// that identity is the single-subscription invariant. `App.initState` forces
/// the first read so the subscription exists from the first frame rather than
/// from whenever the user first opens the store; the store screen reads the same
/// instance and attaches itself as the presentation surface.
///
/// Override it in tests to inject a listener built on stubbed collaborators.
final globalPurchaseListenerProvider = Provider<GlobalPurchaseListener>((ref) {
  final listener = GlobalPurchaseListener(container: ref.container);
  ref.onDispose(listener.dispose);
  return listener;
});
