import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

/// 🧪 디버그 전용 다이얼로그 관리자
class DebugDialogHandler {
  final BuildContext _context;
  final PurchaseService _purchaseService;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;

  DebugDialogHandler({
    required BuildContext context,
    required PurchaseService purchaseService,
    required GlobalKey<LoadingOverlayWithIconState> loadingKey,
  })  : _context = context,
        _purchaseService = purchaseService,
        _loadingKey = loadingKey;

  /// 📊 Pending 상태 다이얼로그
  Future<void> showPendingStatusDialog(Map<String, dynamic> status) async {
    return showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('Pending 구매 정리 상태'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('통계 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 현재 pending: ${status['currentPendingCount']}개'),
              Text('• 총 발견한 pending: ${status['totalPendingFound']}개'),
              Text('• 총 정리한 pending: ${status['totalPendingCleared']}개'),
              Text('• 마지막 정리: ${status['lastCleanupTime'] ?? '없음'}'),
              SizedBox(height: 12),
              if (status['currentPendingItems'] != null &&
                  (status['currentPendingItems'] as List).isNotEmpty) ...[
                Text('현재 pending 구매들:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...(status['currentPendingItems'] as List).map(
                  (item) => Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                        '• ${item['productID']} (${item['transactionDate']})'),
                  ),
                ),
              ] else ...[
                Text('현재 pending 구매 없음',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
              SizedBox(height: 12),
              Text(
                  '정리 성공률: ${status['totalPendingFound'] > 0 ? ((status['totalPendingCleared'] / status['totalPendingFound'] * 100).toStringAsFixed(1)) : '0'}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 🏥 Sandbox 진단 결과 다이얼로그
  Future<void> showSandboxDiagnosisDialog(
      Map<String, dynamic> diagnosis) async {
    return showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('🏥 Sandbox 환경 진단 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('진단 시간: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔍 시스템 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 플랫폼: ${diagnosis['platform'] ?? 'Unknown'}'),
              Text('• 디버그 모드: ${diagnosis['isDebugMode'] ?? 'Unknown'}'),
              Text(
                  '• StoreKit 사용 가능: ${diagnosis['storeKitAvailable'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 구매 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 현재 pending 구매: ${diagnosis['currentPendingCount'] ?? 'Unknown'}개'),
              Text(
                  '• 총 구매 업데이트: ${diagnosis['totalPurchaseUpdates'] ?? 'Unknown'}개'),
              Text(
                  '• 제품 쿼리 성공: ${diagnosis['productQuerySuccessful'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔄 스트림 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 스트림 초기화됨: ${diagnosis['streamInitialized'] ?? 'Unknown'}'),
              Text(
                  '• 구매 컨트롤러 활성: ${diagnosis['purchaseControllerActive'] ?? 'Unknown'}'),
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ 에러:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${diagnosis['error']}',
                    style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 💥 핵폭탄 리셋 확인 다이얼로그
  Future<bool?> showNuclearResetDialog() async {
    return showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('💥 핵폭탄급 Sandbox 리셋'),
        content: Text('''⚠️ 최후의 수단입니다! ⚠️

이 기능은 모든 StoreKit 시스템을 완전히 리셋합니다.

실행할 작업:
💥 모든 StoreKit 연결 완전 끊기 (5초 대기)
💥 시스템 캐시 완전 무효화 (10회 시도)
💥 핵폭탄급 pending 구매 정리 (5라운드)
💥 긴 시스템 안정화 대기 (10초)
💥 완전 새로운 구매 스트림 생성

주의사항:
• 이 과정은 최대 30초 소요됩니다
• 모든 기존 구매 상태가 완전히 리셋됩니다
• 일반 초기화로 해결되지 않는 경우에만 사용하세요

정말로 실행하시겠습니까?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('💥 핵리셋', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  /// 🔄 Sandbox 인증 초기화 확인 다이얼로그
  Future<bool?> showSandboxAuthResetDialog() async {
    return showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('Sandbox 인증창 초기화'),
        content: Text('''Sandbox 환경에서 인증창이 생략되는 문제를 해결합니다.

실행할 작업:
🔄 StoreKit 캐시 완전 초기화 (3회 시도)
🧹 모든 pending 구매 강제 완료
⏰ 시스템 안정화 대기
🔄 구매 스트림 재시작

효과:
✅ Touch ID/Face ID 인증창 재활성화
✅ 이전 인증 상태 완전 리셋
✅ 구매 프로세스 정상화

주의: Sandbox 환경에서만 사용하세요.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('초기화', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  /// 🔐 인증 진단 다이얼로그
  Future<void> showAuthenticationDiagnosisDialog(
      Map<String, dynamic> diagnosis) async {
    return showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('🔐 인증 시스템 진단 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('진단 시간: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔍 인증 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• Touch ID 사용 가능: ${diagnosis['touchIdAvailable'] ?? 'Unknown'}'),
              Text(
                  '• Face ID 사용 가능: ${diagnosis['faceIdAvailable'] ?? 'Unknown'}'),
              Text('• 패스코드 설정됨: ${diagnosis['passcodeSet'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🛡️ 보안 설정:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 생체인증 활성화: ${diagnosis['biometricEnabled'] ?? 'Unknown'}'),
              Text('• 인증 정책: ${diagnosis['authPolicy'] ?? 'Unknown'}'),
              Text('• 최대 시도 횟수: ${diagnosis['maxAttempts'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 시스템 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• iOS 버전: ${diagnosis['iosVersion'] ?? 'Unknown'}'),
              Text('• 디바이스 모델: ${diagnosis['deviceModel'] ?? 'Unknown'}'),
              if (diagnosis['warnings'] != null &&
                  (diagnosis['warnings'] as List).isNotEmpty) ...[
                SizedBox(height: 8),
                Text('⚠️ 경고사항:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange)),
                ...(diagnosis['warnings'] as List).map(
                  (warning) => Text('• $warning',
                      style: TextStyle(color: Colors.orange)),
                ),
              ],
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ 에러:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${diagnosis['error']}',
                    style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// ⚡ 궁극 인증 리셋 확인 다이얼로그
  Future<bool?> showUltimateAuthResetDialog() async {
    return showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text('⚡ 궁극 인증 시스템 리셋'),
        content: Text('''🚨 최종 해결책입니다! 🚨

이 기능은 모든 인증 관련 시스템을 완전히 리셋합니다.

실행할 작업:
⚡ LocalAuthentication 완전 리셋
⚡ Keychain 인증 데이터 완전 삭제
⚡ StoreKit 인증 캐시 완전 무효화
⚡ 시스템 생체인증 상태 재확인
⚡ 모든 인증 정책 초기화

주의사항:
• 이 과정은 최대 15초 소요됩니다
• 모든 저장된 인증 데이터가 삭제됩니다
• Touch ID/Face ID 설정이 초기화될 수 있습니다
• 다른 앱의 인증에도 영향을 줄 수 있습니다

정말로 실행하시겠습니까?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('⚡ 궁극리셋', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 🧪 디버그 핸들러들을 위한 헬퍼 메서드들

  /// Pending 상태 확인 핸들러
  Future<void> handleCheckPendingStatus() async {
    if (!kDebugMode) return;

    try {
      logger.i('[DebugDialogHandler] Pending 상태 확인 시작');

      _loadingKey.currentState?.show();

      final status =
          await _purchaseService.inAppPurchaseService.getPendingCleanupStatus();

      _loadingKey.currentState?.hide();
      await showPendingStatusDialog(status);
    } catch (e) {
      logger.e('[DebugDialogHandler] Pending 상태 확인 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: 'Pending 상태 확인 중 오류가 발생했습니다: $e',
        type: DialogType.error,
      );
    }
  }

  /// Sandbox 진단 핸들러
  Future<void> handleSandboxDiagnosis() async {
    if (!kDebugMode) return;

    try {
      logger.i('[DebugDialogHandler] Sandbox 환경 진단 시작');

      _loadingKey.currentState?.show();

      final diagnosis = await _purchaseService.inAppPurchaseService
          .diagnoseSandboxEnvironment();

      _loadingKey.currentState?.hide();
      await showSandboxDiagnosisDialog(diagnosis);
    } catch (e) {
      logger.e('[DebugDialogHandler] Sandbox 진단 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: 'Sandbox 진단 중 오류가 발생했습니다: $e',
        type: DialogType.error,
      );
    }
  }

  /// 핵폭탄 리셋 핸들러
  Future<void> handleNuclearReset() async {
    if (!kDebugMode) return;

    final shouldReset = await showNuclearResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[DebugDialogHandler] 핵폭탄급 리셋 시작');

      _loadingKey.currentState?.show();

      // 핵폭탄급 Sandbox 인증 시스템 완전 리셋 실행
      await _purchaseService.inAppPurchaseService.nuclearSandboxReset();

      logger.w('[DebugDialogHandler] 핵폭탄급 리셋 완료');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: '''💥 핵폭탄급 Sandbox 리셋 완료!

실행된 작업:
• 모든 StoreKit 연결 완전 끊기 (5초 대기)
• 시스템 캐시 완전 무효화 (10회 시도)
• 핵폭탄급 pending 구매 정리 (5라운드)
• 긴 시스템 안정화 대기 (10초)
• 완전 새로운 구매 스트림 생성

이제 구매를 다시 시도해보세요!''',
      );
    } catch (e) {
      logger.e('[DebugDialogHandler] 핵폭탄급 리셋 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: '핵폭탄급 리셋 중 오류가 발생했습니다: $e',
        type: DialogType.error,
      );
    }
  }

  /// Sandbox 인증 초기화 핸들러
  Future<void> handleSandboxAuthReset() async {
    if (!kDebugMode) return;

    final shouldReset = await showSandboxAuthResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[DebugDialogHandler] Sandbox 인증창 초기화 시작');

      _loadingKey.currentState?.show();

      // Sandbox 인증창 강제 초기화 실행
      await _purchaseService.inAppPurchaseService.forceSandboxAuthReset();

      logger.w('[DebugDialogHandler] Sandbox 인증창 초기화 완료');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: '''Sandbox 인증창 초기화가 완료되었습니다!

다음 구매 시도 시:
• Touch ID/Face ID 인증창이 다시 표시됩니다
• 이전 인증 상태가 모두 리셋되었습니다
• 모든 pending 구매가 정리되었습니다''',
      );
    } catch (e) {
      logger.e('[DebugDialogHandler] Sandbox 인증창 초기화 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: 'Sandbox 인증창 초기화 중 오류가 발생했습니다: $e',
        type: DialogType.error,
      );
    }
  }

  /// 인증 진단 핸들러 (임시 비활성화 - 메서드 없음)
  Future<void> handleAuthenticationDiagnosis() async {
    if (!kDebugMode) return;

    _loadingKey.currentState?.show();
    await Future.delayed(Duration(milliseconds: 500));
    _loadingKey.currentState?.hide();

    showSimpleDialog(
      content: '인증 진단 기능은 개발 중입니다.',
    );
  }

  /// 궁극 인증 리셋 핸들러 (임시 비활성화 - 메서드 없음)
  Future<void> handleUltimateAuthReset() async {
    if (!kDebugMode) return;

    final shouldReset = await showUltimateAuthResetDialog();
    if (shouldReset != true) return;

    _loadingKey.currentState?.show();
    await Future.delayed(Duration(milliseconds: 500));
    _loadingKey.currentState?.hide();

    showSimpleDialog(
      content: '궁극 인증 리셋 기능은 개발 중입니다.',
    );
  }
}
