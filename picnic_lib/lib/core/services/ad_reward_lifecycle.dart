import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:picnic_lib/core/services/wallet_resume_refresher.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns auth and resume events after the app's SDK initialization completes.
/// Auth changes invalidate in-memory work; only resume may read a loaded wallet.
/// Historical ad rewards are never queried by this lifecycle binding.
class AdRewardLifecycle with WidgetsBindingObserver {
  AdRewardLifecycle({
    required WalletAuthGateway auth,
    required WalletResumeRefresher wallet,
    required VoidCallback resetRewards,
    WidgetsBinding? binding,
  }) : _auth = auth,
       _wallet = wallet,
       _resetRewards = resetRewards,
       _binding = binding ?? WidgetsBinding.instance;

  final WalletAuthGateway _auth;
  final WalletResumeRefresher _wallet;
  final VoidCallback _resetRewards;
  final WidgetsBinding _binding;
  StreamSubscription<AuthState>? _subscription;
  String? _owner;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    if (_auth.isEnabled) {
      _syncOwner(_auth.currentSession?.user.id);
      _subscription = _auth.authStateChanges.listen(
        (event) => _syncOwner(event.session?.user.id),
        onError: (Object _, StackTrace _) {
          // Auth exception payloads and stacks may contain credentials.
          logger.w('광고 세션 변경 수신 실패');
        },
      );
    }
    _binding.addObserver(this);
  }

  void _syncOwner(String? owner) {
    if (!_started || owner == _owner) return;
    _owner = owner;
    _wallet.reset();
    _resetRewards();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started || !_auth.isEnabled || state != AppLifecycleState.resumed) {
      return;
    }
    _syncOwner(_auth.currentSession?.user.id);
    unawaited(
      _wallet.refreshOnResume().catchError((Object _, StackTrace _) {
        logger.w('복귀 잔액 갱신 실패');
        return WalletResumeRefreshOutcome.failed;
      }),
    );
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    _binding.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    _owner = null;
    _wallet.reset();
  }
}

final adRewardLifecycleProvider = Provider<AdRewardLifecycle>((ref) {
  final lifecycle = AdRewardLifecycle(
    auth: ref.watch(walletAuthGatewayProvider),
    wallet: ref.watch(walletResumeRefresherProvider),
    resetRewards: ref.read(adRewardRecoveryProvider.notifier).resetForLogout,
  );
  ref.onDispose(lifecycle.dispose);
  return lifecycle;
});
