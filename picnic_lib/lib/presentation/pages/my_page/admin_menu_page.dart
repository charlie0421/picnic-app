import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';

class AdminMenuPage extends ConsumerStatefulWidget {
  const AdminMenuPage({super.key});

  @override
  ConsumerState<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends ConsumerState<AdminMenuPage>
    with RouteAwareStateMixin<AdminMenuPage> {
  @override
  void initState() {
    super.initState();
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
        if (!(data?.isAdmin ?? false)) {
          return const Scaffold(body: Center(child: Text('접근 권한이 없습니다.')));
        }

        return Scaffold(
          body: ListView(
            children: [
              PicnicListItem(
                leading: '캔디 내역',
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: _openCurrencyHistory,
              ),
              PicnicListItem(
                leading: '충전 내역',
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {},
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
                onTap: () async {
                  SnackbarUtil().info('GDPR 동의 초기화 중...', context: context);

                  await ConsentService().logCurrentState();

                  final success = await ConsentService().resetAndReinitialize();

                  await ConsentService().logCurrentState();

                  if (context.mounted) {
                    if (success) {
                      SnackbarUtil().success(
                        'GDPR 동의가 재초기화되었습니다. EEA 모드면 동의 폼이 표시됩니다.',
                        context: context,
                      );
                    } else {
                      SnackbarUtil().error(
                        'GDPR 재초기화 실패. 로그를 확인하세요.',
                        context: context,
                      );
                    }
                  }
                },
              ),
            ],
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

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: '관리자');
    });
  }
}
