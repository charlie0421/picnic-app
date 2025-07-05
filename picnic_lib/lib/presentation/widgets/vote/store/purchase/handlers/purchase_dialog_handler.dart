import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/ui/style.dart';

/// 🎭 구매 관련 다이얼로그 관리자
class PurchaseDialogHandler {
  final BuildContext _context;
  final PurchaseService _purchaseService;

  PurchaseDialogHandler({
    required BuildContext context,
    required PurchaseService purchaseService,
  })  : _context = context,
        _purchaseService = purchaseService;

  /// 🔒 구매 확인 다이얼로그 - 우발적 구매 방지
  Future<bool?> showPurchaseConfirmDialog({
    required Map<String, dynamic> serverProduct,
    required List<ProductDetails> storeProducts,
  }) async {
    return await showDialog<bool>(
      context: _context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                package: 'picnic_lib',
                'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
                width: 24,
                height: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('purchase_confirm_title'),
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('purchase_confirm_message'),
                style: getTextStyle(AppTypo.body14R, AppColors.grey700),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary500.withValues(alpha: 0.08),
                      AppColors.primary500.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 스타캔디 아이콘 - 더 크고 매력적으로
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary500
                                    .withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            package: 'picnic_lib',
                            'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serverProduct['id'],
                                style: getTextStyle(
                                    AppTypo.body16B, AppColors.grey900),
                              ),
                              SizedBox(height: 6),
                              // 상품 설명을 파싱해서 메인 설명과 보너스 분리
                              ...(() {
                                final fullDescription = getLocaleTextFromJson(
                                    serverProduct['description']);

                                // '+' 기호를 기준으로 분리
                                if (fullDescription.contains('+')) {
                                  final parts = fullDescription.split('+');
                                  final mainDescription = parts[0].trim();
                                  final bonusDescription =
                                      '+${parts.sublist(1).join('+').trim()}';

                                  return [
                                    Text(
                                      mainDescription,
                                      style: getTextStyle(AppTypo.caption12R,
                                          AppColors.grey600),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      bonusDescription,
                                      style: getTextStyle(AppTypo.caption12B,
                                          AppColors.point900),
                                    ),
                                  ];
                                } else {
                                  // '+' 기호가 없는 경우 전체를 메인 설명으로 표시
                                  return [
                                    Text(
                                      fullDescription,
                                      style: getTextStyle(AppTypo.caption12R,
                                          AppColors.grey600),
                                    ),
                                  ];
                                }
                              })(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // 구분선
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary500.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // 가격 정보 - 더 강조해서 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('purchase_payment_amount'),
                          style:
                              getTextStyle(AppTypo.body14M, AppColors.grey600),
                        ),
                        Text(
                          '${serverProduct['price']} \$',
                          style: getTextStyle(
                              AppTypo.body16B, AppColors.primary500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                t('cancel'),
                style: getTextStyle(AppTypo.body14R, AppColors.grey500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Text(
                t('purchase_confirm_button'),
                style: getTextStyle(AppTypo.body14B, Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🔴 에러 다이얼로그
  Future<void> showErrorDialog(String message) async {
    try {
      final envInfo = await _purchaseService.receiptVerificationService
          .getEnvironmentInfo();
      final isTestFlight = envInfo['environment'] == 'sandbox' &&
          !envInfo['isDebugMode'] &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      final shouldShowDebugInfo = kDebugMode || isTestFlight;

      if (shouldShowDebugInfo) {
        final debugInfo = '''
환경: ${envInfo['environment']}
플랫폼: ${envInfo['platform']}
설치 스토어: ${envInfo['installerStore'] ?? 'null'}
앱 이름: ${envInfo['appName']}
버전: ${envInfo['version']} (${envInfo['buildNumber']})
디버그 모드: ${envInfo['isDebugMode']}

오류: $message
''';
        showSimpleDialog(content: debugInfo, type: DialogType.error);
      } else {
        showSimpleDialog(content: message, type: DialogType.error);
      }
    } catch (e) {
      showSimpleDialog(content: message, type: DialogType.error);
    }
  }

  /// 🎉 구매 성공 다이얼로그
  Future<void> showSuccessDialog() async {
    logger.i('[PurchaseDialogHandler] Showing success dialog');
    final message = t('dialog_message_purchase_success');
    showSimpleDialog(content: message);
  }

  /// ⏰ 늦은 구매 성공 다이얼로그
  Future<void> showLatePurchaseSuccessDialog() async {
    logger.i('[PurchaseDialogHandler] Showing late purchase success dialog');

    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 구매 완료'),
        content: Text('''구매가 성공적으로 완료되었습니다!

⏰ 인증이 예상보다 오래 걸려서 타임아웃 안내가 표시되었지만, 실제로는 정상적으로 구매가 처리되었습니다.

✅ 스타캔디가 정상적으로 지급되었습니다
✅ 구매 내역이 서버에 기록되었습니다

이는 Touch ID/Face ID 인증 시 발생할 수 있는 정상적인 상황입니다.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// ⚠️ 예상치 못한 중복 에러 다이얼로그
  Future<void> showUnexpectedDuplicateDialog() async {
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('서버 처리 중 문제 발생'),
        content: Text('''서버에서 소모성 상품 중복 검사를 완화했지만 여전히 오류가 발생했습니다.

가능한 원인:
1. 서버 배포가 아직 완전히 적용되지 않음
2. 다른 종류의 네트워크 오류
3. 잠시 후 다시 시도하면 해결될 가능성

해결 방법:
1. 1-2분 후 다시 시도 (서버 배포 완료 대기)
2. 그래도 안 되면 앱 재시작
3. 문제가 지속되면 고객지원 문의

소모성 상품이므로 중복 구매가 정상적으로 허용되어야 합니다.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
