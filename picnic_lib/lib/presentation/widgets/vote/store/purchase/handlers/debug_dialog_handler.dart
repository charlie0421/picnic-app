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
        title: Text('Pending Purchase Cleanup Status'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Statistics:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Current pending: ${status['currentPendingCount']} items'),
              Text(
                  '• Total pending found: ${status['totalPendingFound']} items'),
              Text(
                  '• Total pending cleared: ${status['totalPendingCleared']} items'),
              Text('• Last cleanup: ${status['lastCleanupTime'] ?? 'None'}'),
              SizedBox(height: 12),
              if (status['currentPendingItems'] != null &&
                  (status['currentPendingItems'] as List).isNotEmpty) ...[
                Text('Current pending purchases:',
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
                Text('No pending purchases currently',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
              SizedBox(height: 12),
              Text(
                  'Cleanup success rate: ${status['totalPendingFound'] > 0 ? ((status['totalPendingCleared'] / status['totalPendingFound'] * 100).toStringAsFixed(1)) : '0'}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text('OK'),
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
        title: Text('🏥 Sandbox Environment Diagnosis Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Diagnosis time: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔍 System Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Platform: ${diagnosis['platform'] ?? 'Unknown'}'),
              Text('• Debug mode: ${diagnosis['isDebugMode'] ?? 'Unknown'}'),
              Text(
                  '• StoreKit available: ${diagnosis['storeKitAvailable'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 Purchase Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• Current pending purchases: ${diagnosis['currentPendingCount'] ?? 'Unknown'} items'),
              Text(
                  '• Total purchase updates: ${diagnosis['totalPurchaseUpdates'] ?? 'Unknown'} items'),
              Text(
                  '• Product query successful: ${diagnosis['productQuerySuccessful'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔄 Stream Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• Stream initialized: ${diagnosis['streamInitialized'] ?? 'Unknown'}'),
              Text(
                  '• Purchase controller active: ${diagnosis['purchaseControllerActive'] ?? 'Unknown'}'),
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ Error:',
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
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text('OK'),
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
        title: Text('💥 Nuclear-level Sandbox Reset'),
        content: Text('''⚠️ This is the last resort! ⚠️

This function completely resets all StoreKit systems.

Actions to be performed:
💥 Completely disconnect all StoreKit connections (5 second wait)
💥 Complete system cache invalidation (10 attempts)
💥 Nuclear-level pending purchase cleanup (5 rounds)
💥 Long system stabilization wait (10 seconds)
💥 Create completely new purchase stream

Precautions:
• This process takes up to 30 seconds
• All existing purchase states will be completely reset
• Only use when general initialization doesn't solve the problem

Do you really want to proceed?'''),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('💥 Nuclear Reset',
                style: TextStyle(color: Colors.purple)),
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
        title: Text('Sandbox Authentication Reset'),
        content: Text(
            '''Resolves the issue where authentication dialogs are skipped in Sandbox environment.

Actions to be performed:
🔄 Complete StoreKit cache initialization (3 attempts)
🧹 Force complete all pending purchases
⏰ System stabilization wait
🔄 Restart purchase stream

Effects:
✅ Reactivate Touch ID/Face ID authentication dialog
✅ Complete reset of previous authentication state
✅ Normalize purchase process

Note: Use only in Sandbox environment.'''),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Reset', style: TextStyle(color: Colors.orange)),
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
        title: Text('🔐 Authentication System Diagnosis Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Diagnosis time: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔍 Authentication Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• Touch ID available: ${diagnosis['touchIdAvailable'] ?? 'Unknown'}'),
              Text(
                  '• Face ID available: ${diagnosis['faceIdAvailable'] ?? 'Unknown'}'),
              Text('• Passcode set: ${diagnosis['passcodeSet'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🛡️ Security Settings:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• Biometric enabled: ${diagnosis['biometricEnabled'] ?? 'Unknown'}'),
              Text(
                  '• Authentication policy: ${diagnosis['authPolicy'] ?? 'Unknown'}'),
              Text('• Max attempts: ${diagnosis['maxAttempts'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 System Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• iOS version: ${diagnosis['iosVersion'] ?? 'Unknown'}'),
              Text('• Device model: ${diagnosis['deviceModel'] ?? 'Unknown'}'),
              if (diagnosis['warnings'] != null &&
                  (diagnosis['warnings'] as List).isNotEmpty) ...[
                SizedBox(height: 8),
                Text('⚠️ Warnings:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange)),
                ...(diagnosis['warnings'] as List).map(
                  (warning) => Text('• $warning',
                      style: TextStyle(color: Colors.orange)),
                ),
              ],
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ Error:',
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
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text('OK'),
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
        title: Text('⚡ Ultimate Authentication System Reset'),
        content: Text('''🚨 This is the final solution! 🚨

This function completely resets all authentication-related systems.

Actions to be performed:
⚡ Complete LocalAuthentication reset
⚡ Complete deletion of Keychain authentication data
⚡ Complete invalidation of StoreKit authentication cache
⚡ Re-verify system biometric authentication status
⚡ Initialize all authentication policies

Precautions:
• This process takes up to 15 seconds
• All stored authentication data will be deleted
• Touch ID/Face ID settings may be reset
• May affect authentication in other apps

Do you really want to proceed?'''),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child:
                Text('⚡ Ultimate Reset', style: TextStyle(color: Colors.red)),
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
        content: 'Error occurred while checking pending status: $e',
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
        content: 'Error occurred during sandbox diagnosis: $e',
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
        content: '''💥 Nuclear-level Sandbox reset completed!

Actions performed:
• Completely disconnected all StoreKit connections (5 second wait)
• Complete system cache invalidation (10 attempts)
• Nuclear-level pending purchase cleanup (5 rounds)
• Long system stabilization wait (10 seconds)
• Create completely new purchase stream

You can now try purchasing again!''',
      );
    } catch (e) {
      logger.e('[DebugDialogHandler] 핵폭탄급 리셋 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: 'Error occurred during nuclear reset: $e',
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
        content: '''Sandbox authentication reset completed!

For next purchase attempt:
• Touch ID/Face ID authentication dialog will be displayed again
• All previous authentication states have been reset
• All pending purchases have been cleared''',
      );
    } catch (e) {
      logger.e('[DebugDialogHandler] Sandbox 인증창 초기화 실패: $e');

      _loadingKey.currentState?.hide();
      showSimpleDialog(
        content: 'Error occurred during sandbox authentication reset: $e',
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
      content: 'Authentication diagnosis feature is under development.',
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
      content: 'Ultimate authentication reset feature is under development.',
    );
  }
}
