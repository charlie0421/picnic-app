import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/services/sandbox_refund_candidate_store.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/controllers/admin_gdpr_reset_controller.dart';
import 'package:picnic_lib/presentation/pages/my_page/charge_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/sandbox_refund_request_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';

typedef AppReloadCallback = void Function(BuildContext context);

class AdminMenuPage extends ConsumerStatefulWidget {
  const AdminMenuPage({
    super.key,
    this.gdprResetController,
    this.reloadApp,
    this.isIOS,
    this.sandboxRefundCandidates,
  });

  final AdminGdprResetController? gdprResetController;
  final AppReloadCallback? reloadApp;

  /// Defaults to [Platform.isIOS]. Injectable for host tests.
  final bool? isIOS;
  final SandboxRefundCandidateStore? sandboxRefundCandidates;

  @override
  ConsumerState<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends ConsumerState<AdminMenuPage>
    with RouteAwareStateMixin<AdminMenuPage> {
  late final AdminGdprResetController _gdprResetController;
  late final AppReloadCallback _reloadApp;
  bool _isGdprResetInProgress = false;
  late final SandboxRefundCandidateStore _sandboxRefundCandidates;
  bool _hasSandboxRefundCandidates = false;

  @override
  void initState() {
    super.initState();
    _gdprResetController =
        widget.gdprResetController ??
        AdminGdprResetController(
          resetAndReinitialize: ConsentService().resetAndReinitialize,
          logCurrentState: ConsentService().logCurrentState,
        );
    _reloadApp = widget.reloadApp ?? Phoenix.rebirth;
    _sandboxRefundCandidates =
        widget.sandboxRefundCandidates ?? SandboxRefundCandidateStore();
    _loadSandboxRefundCandidates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavigation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoState = ref.watch(userInfoProvider);

    return userInfoState.when(
      data: (data) {
        if (!(data?.hasAdminAccess ?? false)) {
          return const Scaffold(body: Center(child: Text('접근 권한이 없습니다.')));
        }

        return Scaffold(
          body: Padding(
            key: const Key('admin-menu-content'),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                PicnicListItem(
                  leading: '캔디 내역',
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: _openCurrencyHistory,
                ),
                PicnicListItem(
                  leading: '충전 내역',
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: _openChargeHistory,
                ),
                PicnicListItem(
                  leading: 'Ad Inspector',
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: () {
                    MobileAds.instance.openAdInspector((error) {
                      if (error != null) {
                        logger.e('Ad Inspector error: ${error.message}');
                      } else {
                        logger.i('Ad Inspector closed');
                      }
                    });
                  },
                ),
                PicnicListItem(
                  leading: 'Reset & Reload GDPR',
                  assetPath: 'assets/icons/arrow_right_style=line.svg',
                  onTap: _isGdprResetInProgress ? null : _resetAndReloadGdpr,
                ),
                // sandbox(TestFlight) 구매를 정산한 iOS 기기에서만 보인다.
                if (_hasSandboxRefundCandidates)
                  PicnicListItem(
                    leading: '테스트 환불 요청',
                    assetPath: 'assets/icons/arrow_right_style=line.svg',
                    onTap: _openSandboxRefundRequest,
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => ui.buildLoadingOverlay(),
      error: (error, stackTrace) =>
          buildErrorView(context, error: error, stackTrace: stackTrace),
    );
  }

  void _openCurrencyHistory() {
    ref
        .read(navigationInfoProvider.notifier)
        .setCurrentMyPage(const CurrencyHistoryPage());
  }

  void _openChargeHistory() {
    ref
        .read(navigationInfoProvider.notifier)
        .setCurrentMyPage(const ChargeHistoryPage());
  }

  Future<void> _loadSandboxRefundCandidates() async {
    if (!(widget.isIOS ?? Platform.isIOS)) return;
    final candidates = await _sandboxRefundCandidates.load();
    if (!mounted || candidates.isEmpty) return;
    setState(() => _hasSandboxRefundCandidates = true);
  }

  void _openSandboxRefundRequest() {
    ref
        .read(navigationInfoProvider.notifier)
        .setCurrentMyPage(
          SandboxRefundRequestPage(candidates: _sandboxRefundCandidates),
        );
  }

  Future<void> _resetAndReloadGdpr() async {
    if (_isGdprResetInProgress) return;

    setState(() => _isGdprResetInProgress = true);
    SnackbarUtil().info('GDPR 동의 초기화 중...', context: context);

    final result = await _gdprResetController.reset();

    if (!mounted || !context.mounted) return;
    setState(() => _isGdprResetInProgress = false);

    switch (result) {
      case AdminGdprResetResult.success:
        SnackbarUtil().success(
          'GDPR 동의가 재초기화되었습니다. EEA 모드면 동의 폼이 표시됩니다.',
          context: context,
        );
        _reloadApp(context);
        return;
      case AdminGdprResetResult.failure:
        SnackbarUtil().error('GDPR 재초기화 실패. 로그를 확인하세요.', context: context);
        return;
      case AdminGdprResetResult.inProgress:
        return;
    }
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: '관리자');
    });
  }
}
