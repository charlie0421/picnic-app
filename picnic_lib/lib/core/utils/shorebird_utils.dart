import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'dart:async';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';

final updater = shorebird.ShorebirdUpdater();

class ShorebirdUtils {
  static Future<void> checkAndUpdate() async {
    try {
      logger.i('Shorebird 업데이트 체크 시작');
      final status = await updater.checkForUpdate();
      logger.i('Shorebird 상태: $status');

      if (status == shorebird.UpdateStatus.outdated) {
        logger.i('Shorebird 업데이트 필요 - 업데이트 시작');

        // 업데이트 시도 전 상태 확인
        final patchBefore = await updater.readCurrentPatch();
        logger.i('업데이트 전 패치 정보: ${patchBefore?.number}');

        await updater.update();

        // 업데이트 후 상태 확인
        final patchAfter = await updater.readCurrentPatch();
        logger.i('업데이트 후 패치 정보: ${patchAfter?.number}');

        // 패치가 실제로 변경되었는지 확인
        if (patchBefore?.number != patchAfter?.number) {
          logger.i(
              'Shorebird 업데이트 성공적으로 완료 (${patchBefore?.number} → ${patchAfter?.number})');
        } else {
          logger.w('Shorebird 업데이트가 완료되었지만 패치 번호가 변경되지 않음');
        }
      } else {
        logger.i('Shorebird 최신 버전 유지 중 (상태: $status)');
      }
    } catch (e, stackTrace) {
      logger.e('Shorebird 업데이트 중 오류 발생: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<shorebird.Patch?> checkPatch() async {
    try {
      final patch = await updater.readCurrentPatch();
      logger.i('현재 패치 상태: ${patch?.number ?? "패치 없음"}');
      return patch;
    } catch (e, stackTrace) {
      logger.e('Shorebird 패치 정보 읽기 중 오류 발생: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// 업데이트 상태를 더 자세히 확인하는 메서드
  static Future<Map<String, dynamic>> getDetailedStatus() async {
    try {
      final status = await updater.checkForUpdate();
      final patch = await updater.readCurrentPatch();

      return {
        'updateStatus': status.toString(),
        'currentPatch': patch?.number,
        'isRestartRequired': status == shorebird.UpdateStatus.restartRequired,
        'isOutdated': status == shorebird.UpdateStatus.outdated,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      logger.e('Shorebird 상세 상태 확인 중 오류: $e', stackTrace: stackTrace);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 패치 후 재시작 문제 진단 메서드
  static Future<Map<String, dynamic>> diagnosePatchRestartIssue() async {
    final diagnostics = <String, dynamic>{};

    try {
      // 1. 현재 Shorebird 상태 확인
      final status = await updater.checkForUpdate();
      diagnostics['currentStatus'] = status.toString();

      // 2. 현재 패치 정보
      final patch = await updater.readCurrentPatch();
      diagnostics['currentPatchNumber'] = patch?.number;

      // 3. 재시작이 필요한 상태인지 확인
      diagnostics['needsRestart'] =
          status == shorebird.UpdateStatus.restartRequired;

      // 4. 업데이트가 가능한 상태인지 확인
      diagnostics['hasUpdates'] = status == shorebird.UpdateStatus.outdated;

      // 5. 진단 시점 기록
      diagnostics['diagnosticTime'] = DateTime.now().toIso8601String();

      // 6. 권장 조치 결정
      List<String> recommendations = [];

      if (status == shorebird.UpdateStatus.restartRequired) {
        recommendations.add('앱을 완전히 종료하고 다시 시작하세요');
        recommendations.add('Phoenix.rebirth() 호출을 시도하세요');
      } else if (status == shorebird.UpdateStatus.outdated) {
        recommendations.add('업데이트를 먼저 다운로드하세요');
        recommendations.add('업데이트 후 재시작하세요');
      } else {
        recommendations.add('현재 최신 상태입니다');
      }

      diagnostics['recommendations'] = recommendations;

      logger.i('패치 재시작 진단 완료: $diagnostics');
    } catch (e, stackTrace) {
      logger.e('패치 재시작 진단 중 오류: $e', stackTrace: stackTrace);
      diagnostics['error'] = e.toString();
      diagnostics['errorTime'] = DateTime.now().toIso8601String();
    }

    return diagnostics;
  }

  /// 강제 재시작 상태 확인 및 실행
  static Future<bool> forceCheckAndRestart() async {
    try {
      logger.i('강제 재시작 체크 시작');

      final diagnostics = await diagnosePatchRestartIssue();
      logger.i('진단 결과: $diagnostics');

      if (diagnostics['needsRestart'] == true) {
        logger.w('재시작이 필요한 상태가 감지됨');
        return true; // 호출자에게 재시작이 필요함을 알림
      }

      if (diagnostics['hasUpdates'] == true) {
        logger.i('업데이트 후 재시작 필요');
        await checkAndUpdate();
        return true; // 업데이트 후 재시작 필요
      }

      logger.i('재시작이 필요하지 않음');
      return false;
    } catch (e, stackTrace) {
      logger.e('강제 재시작 체크 중 오류: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// 수동 패치 상태 체크 (설정 페이지용)
  static Future<Map<String, dynamic>> checkPatchStatusForSettings() async {
    try {
      logger.i('설정 페이지용 패치 상태 체크 시작');

      // 1. 현재 상태 확인
      final status = await updater.checkForUpdate();
      final patch = await updater.readCurrentPatch();

      final result = {
        'updateStatus': status.toString(),
        'currentPatch': patch?.number,
        'isRestartRequired': status == shorebird.UpdateStatus.restartRequired,
        'isOutdated': status == shorebird.UpdateStatus.outdated,
        'isUpToDate': status == shorebird.UpdateStatus.upToDate,
        'timestamp': DateTime.now().toIso8601String(),
        'success': true,
      };

      logger.i('설정 페이지용 패치 상태 체크 완료: $result');
      return result;
    } catch (e, stackTrace) {
      logger.e('설정 페이지용 패치 상태 체크 중 오류: $e', stackTrace: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 강제 패치 다운로드 및 적용 (설정 페이지용)
  static Future<Map<String, dynamic>> downloadAndApplyPatch() async {
    try {
      logger.i('강제 패치 다운로드 및 적용 시작');

      // 1. 현재 상태 확인
      final initialStatus = await updater.checkForUpdate();
      if (initialStatus != shorebird.UpdateStatus.outdated) {
        return {
          'success': false,
          'message': '다운로드할 패치가 없습니다',
          'status': initialStatus.toString(),
        };
      }

      // 2. 패치 다운로드 전 상태
      final patchBefore = await updater.readCurrentPatch();
      logger.i('패치 다운로드 전: ${patchBefore?.number}');

      // 3. 패치 다운로드 및 적용
      await updater.update();

      // 4. 패치 적용 후 상태 확인
      final patchAfter = await updater.readCurrentPatch();
      final finalStatus = await updater.checkForUpdate();

      logger.i('패치 다운로드 후: ${patchAfter?.number}, 상태: $finalStatus');

      final result = {
        'success': true,
        'patchBefore': patchBefore?.number,
        'patchAfter': patchAfter?.number,
        'patchChanged': patchBefore?.number != patchAfter?.number,
        'needsRestart': finalStatus == shorebird.UpdateStatus.restartRequired,
        'finalStatus': finalStatus.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      logger.i('강제 패치 다운로드 및 적용 완료: $result');
      return result;
    } catch (e, stackTrace) {
      logger.e('강제 패치 다운로드 및 적용 중 오류: $e', stackTrace: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 패치 감지 문제 종합 진단 도구
  static Future<Map<String, dynamic>> diagnosePatchDetectionIssue() async {
    final diagnosis = <String, dynamic>{};

    try {
      logger.i('🔍 패치 감지 문제 종합 진단 시작');

      // 1. 기본 환경 정보
      diagnosis['platform'] = {
        'isWeb': UniversalPlatform.isWeb,
        'isMobile': UniversalPlatform.isMobile,
        'operatingSystem': UniversalPlatform.operatingSystem,
      };

      // 2. 네트워크 상태 확인
      try {
        final networkService = NetworkConnectivityService();
        final hasNetwork = await networkService.checkOnlineStatus();
        diagnosis['network'] = {
          'isOnline': hasNetwork,
          'checkedAt': DateTime.now().toIso8601String(),
        };

        if (!hasNetwork) {
          diagnosis['recommendations'] = [
            '네트워크 연결을 확인해주세요',
            '인터넷 연결이 안정적인지 확인해주세요'
          ];
        }
      } catch (e) {
        diagnosis['network'] = {
          'error': e.toString(),
          'isOnline': false,
        };
      }

      // 3. Shorebird 상태 확인
      try {
        final currentPatch = await updater.readCurrentPatch();
        final updateStatus = await updater.checkForUpdate();

        diagnosis['shorebird'] = {
          'currentPatch': currentPatch?.number,
          'updateStatus': updateStatus.toString(),
          'isOutdated': updateStatus == shorebird.UpdateStatus.outdated,
          'isRestartRequired':
              updateStatus == shorebird.UpdateStatus.restartRequired,
          'isUpToDate': updateStatus == shorebird.UpdateStatus.upToDate,
          'checkedAt': DateTime.now().toIso8601String(),
        };

        // 4. 권장사항 생성
        List<String> recommendations = diagnosis['recommendations'] ?? [];

        if (updateStatus == shorebird.UpdateStatus.outdated) {
          recommendations.addAll(
              ['새로운 패치가 감지되었습니다', '설정 페이지에서 "Patch Status"를 클릭하여 패치를 다운로드하세요']);
        } else if (updateStatus == shorebird.UpdateStatus.restartRequired) {
          recommendations.addAll(['패치가 다운로드되었습니다', '앱을 재시작하여 패치를 적용하세요']);
        } else if (updateStatus == shorebird.UpdateStatus.upToDate) {
          recommendations.addAll(['현재 최신 패치를 사용 중입니다', '패치 감지에 문제가 없습니다']);
        }

        diagnosis['recommendations'] = recommendations;
      } catch (e, stackTrace) {
        diagnosis['shorebird'] = {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        };

        diagnosis['recommendations'] = [
          'Shorebird 패치 시스템에 오류가 발생했습니다',
          '앱을 완전히 종료하고 다시 시작해보세요',
          '문제가 지속되면 개발팀에 문의해주세요'
        ];
      }

      // 5. 진단 요약
      diagnosis['summary'] = _generateDiagnosisSummary(diagnosis);
      diagnosis['diagnosticTime'] = DateTime.now().toIso8601String();

      logger.i('🏁 패치 감지 문제 종합 진단 완료');
      logger.i('진단 결과: ${diagnosis['summary']}');

      return diagnosis;
    } catch (e, stackTrace) {
      logger.e('💥 패치 감지 진단 중 오류: $e', stackTrace: stackTrace);

      return {
        'error': e.toString(),
        'recommendations': ['진단 도구 실행 중 오류가 발생했습니다', '앱을 재시작해보세요'],
        'diagnosticTime': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 진단 결과 요약 생성
  static String _generateDiagnosisSummary(Map<String, dynamic> diagnosis) {
    final network = diagnosis['network'];
    final shorebird = diagnosis['shorebird'];

    if (network != null && network['isOnline'] == false) {
      return '네트워크 연결 문제';
    }

    if (shorebird != null && shorebird['error'] != null) {
      return 'Shorebird 시스템 오류';
    }

    if (shorebird != null) {
      final status = shorebird['updateStatus'];
      if (status == 'UpdateStatus.outdated') {
        return '새로운 패치 감지됨';
      } else if (status == 'UpdateStatus.restartRequired') {
        return '재시작 필요';
      } else if (status == 'UpdateStatus.upToDate') {
        return '최신 상태';
      }
    }

    return '진단 완료';
  }

  /// 패치 감지 문제 자동 해결 시도
  static Future<Map<String, dynamic>> autoFixPatchDetection() async {
    try {
      logger.i('🔧 패치 감지 문제 자동 해결 시도');

      // 1. 먼저 진단 실행
      final diagnosis = await diagnosePatchDetectionIssue();

      // 2. 네트워크 문제인 경우
      if (diagnosis['network']?['isOnline'] == false) {
        return {
          'success': false,
          'message': '네트워크 연결이 필요합니다',
          'diagnosis': diagnosis,
        };
      }

      // 3. Shorebird 오류인 경우
      if (diagnosis['shorebird']?['error'] != null) {
        return {
          'success': false,
          'message': 'Shorebird 시스템 오류로 인해 자동 해결할 수 없습니다',
          'diagnosis': diagnosis,
        };
      }

      // 4. 패치가 감지된 경우 자동 다운로드 시도
      if (diagnosis['shorebird']?['isOutdated'] == true) {
        logger.i('🔄 새로운 패치 자동 다운로드 시도');
        final downloadResult = await downloadAndApplyPatch();

        return {
          'success': downloadResult['success'],
          'message': downloadResult['success']
              ? '패치가 자동으로 다운로드되었습니다'
              : '패치 다운로드 실패: ${downloadResult['error']}',
          'diagnosis': diagnosis,
          'downloadResult': downloadResult,
        };
      }

      // 5. 이미 최신 상태인 경우
      return {
        'success': true,
        'message': '패치 감지에 문제가 없습니다 (최신 상태)',
        'diagnosis': diagnosis,
      };
    } catch (e, stackTrace) {
      logger.e('💥 자동 해결 시도 중 오류: $e', stackTrace: stackTrace);

      return {
        'success': false,
        'message': '자동 해결 시도 중 오류가 발생했습니다',
        'error': e.toString(),
      };
    }
  }
}
