import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 패치 알림 서비스
///
/// 패치 다운로드 완료, 적용 완료 등의 상태를 사용자에게 알림
class PatchNotificationService {
  static const String _lastPatchNumberKey = 'last_applied_patch_number';

  /// 패치가 방금 적용되었는지 확인 (스플래시 화면용)
  ///
  /// 앱 시작 시 호출하여 패치가 새로 적용되었는지 확인
  /// 확인 후 플래그는 자동으로 초기화됨
  static Future<bool> checkAndClearPatchApplied() async {
    try {
      // 현재 패치 번호 확인
      final currentPatch = await updater.readCurrentPatch();
      final currentPatchNumber = currentPatch?.number;

      // 저장된 마지막 패치 번호 확인
      final prefs = await SharedPreferences.getInstance();
      final lastPatchNumber = prefs.getInt(_lastPatchNumberKey);

      logger.i('📊 패치 번호 비교: 저장된=$lastPatchNumber, 현재=$currentPatchNumber');

      // 패치 번호가 변경되었는지 확인
      final wasApplied = currentPatchNumber != null &&
          lastPatchNumber != null &&
          currentPatchNumber != lastPatchNumber;

      if (wasApplied) {
        logger.i('✅ 새 패치 적용 감지: $lastPatchNumber → $currentPatchNumber');
      }

      // 현재 패치 번호 저장
      if (currentPatchNumber != null) {
        await prefs.setInt(_lastPatchNumberKey, currentPatchNumber);
      }

      return wasApplied;
    } catch (e) {
      logger.e('패치 적용 확인 실패: $e');
      return false;
    }
  }

  /// 현재 패치 번호 저장 (스플래시 화면에서 호출)
  ///
  /// 앱 시작 시 현재 패치 번호를 저장하여 다음 시작 시 비교할 수 있도록 함
  static Future<void> saveCurrentPatchNumber() async {
    try {
      final currentPatch = await updater.readCurrentPatch();
      final currentPatchNumber = currentPatch?.number;

      if (currentPatchNumber != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_lastPatchNumberKey, currentPatchNumber);
        logger.i('💾 현재 패치 번호 저장: $currentPatchNumber');
      }
    } catch (e) {
      logger.e('패치 번호 저장 실패: $e');
    }
  }

  /// 패치 다운로드 완료 알림 표시
  ///
  /// [message] 표시할 메시지 (L10N 적용된 문자열)
  static void showDownloadCompleteNotification(String message) {
    logger.i('📢 패치 다운로드 완료 알림 표시');
    SnackbarUtil().info(
      message,
      duration: const Duration(seconds: 5),
      icon: Icons.system_update_rounded,
    );
  }

  /// 저장된 패치 번호 초기화 (테스트용)
  static Future<void> resetSavedPatchNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPatchNumberKey);
    logger.i('🔄 저장된 패치 번호 초기화됨');
  }
}
