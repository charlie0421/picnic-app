import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
// MemoryLeakReport 충돌 해결을 위해 별칭 사용
import 'package:picnic_lib/services/memory_profiler_report_service.dart';

/// 테스트 환경에서 메모리 프로파일러를 사용하기 위한 확장 기능
extension MemoryProfilerTestExtension on WidgetTester {
  /// 메모리 프로파일러를 테스트용으로 초기화합니다.
  ///
  /// [autoSnapshot]이 true면 자동 스냅샷 기능을 활성화합니다.
  /// [snapshotIntervalSeconds]는 자동 스냅샷 간격(초)입니다.
  /// [leakThresholdMB]는 메모리 누수로 간주할 임계값(MB)입니다.
  ///
  /// 반환값은 초기화 성공 여부입니다.
  Future<bool> initializeMemoryProfiler({
    bool autoSnapshot = true,
    int snapshotIntervalSeconds = 10,
    int leakThresholdMB = 10,
  }) async {
    try {
      // 테스트 환경에서 프로파일러 초기화
      MemoryProfiler.instance.initialize(
        enabled: true,
        enableAutoSnapshot: autoSnapshot,
        autoSnapshotIntervalSeconds: snapshotIntervalSeconds,
      );

      logger.i('테스트용 메모리 프로파일러 초기화 성공');
      return true;
    } catch (e) {
      logger.e('테스트용 메모리 프로파일러 초기화 실패: $e');
      return false;
    }
  }

  /// 메모리 스냅샷을 생성합니다.
  ///
  /// [label]은 스냅샷의 레이블입니다.
  /// [metadata]는 스냅샷과 함께 저장할 메타데이터입니다.
  Future<MemorySnapshot?> takeMemorySnapshot(
    String label, {
    Map<String, dynamic>? metadata,
    bool includeStackTrace = true,
  }) async {
    final snapshot = MemoryProfiler.instance.takeSnapshot(
      label,
      metadata: metadata,
      level: MemoryProfiler.snapshotLevelHigh,
      includeStackTrace: includeStackTrace,
    );

    if (snapshot != null) {
      logger.i('테스트에서 메모리 스냅샷 생성: $label');
    }

    return snapshot;
  }

  /// 두 스냅샷 사이의 메모리 차이를 계산합니다.
  ///
  /// [beforeLabel]은 이전 스냅샷의 레이블입니다.
  /// [afterLabel]은 이후 스냅샷의 레이블입니다.
  MemoryDiff? calculateMemoryDiff(String beforeLabel, String afterLabel) {
    return MemoryProfiler.instance.calculateDiff(beforeLabel, afterLabel);
  }

  /// 위젯 테스트 중 특정 작업의 메모리 사용량을 프로파일링합니다.
  ///
  /// [description]은 작업에 대한 설명입니다.
  /// [action]은 프로파일링할 작업입니다.
  /// [failTestOnLeak]이 true이고 누수가 감지되면 테스트가 실패합니다.
  /// [thresholdMB]는 누수로 간주할 임계값(MB)입니다.
  Future<MemoryDiff?> profileWidgetAction(
    String description,
    Future<void> Function() action, {
    bool failTestOnLeak = false,
    int thresholdMB = 10,
  }) async {
    final beforeLabel = 'test_${description}_before';
    final afterLabel = 'test_${description}_after';

    // 작업 전 스냅샷
    await takeMemorySnapshot(beforeLabel, metadata: {
      'type': 'test_action',
      'description': description,
      'threshold_mb': thresholdMB,
    });

    // 작업 실행
    await action();

    // 프레임 처리 대기
    await pumpAndSettle();

    // GC 유도를 위한 지연
    await Future.delayed(const Duration(milliseconds: 500));

    // 작업 후 스냅샷
    await takeMemorySnapshot(afterLabel, metadata: {
      'type': 'test_action',
      'description': description,
      'threshold_mb': thresholdMB,
    });

    // 메모리 차이 계산
    final diff = calculateMemoryDiff(beforeLabel, afterLabel);

    if (diff != null) {
      final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
      logger.i('테스트 작업 "$description"의 메모리 사용: ${heapDiffMB}MB');

      // 누수 감지 및 테스트 실패 처리
      if (failTestOnLeak && heapDiffMB > thresholdMB) {
        fail(
            '메모리 누수 감지: 작업 "$description"에서 ${heapDiffMB}MB 메모리 증가 (임계값: ${thresholdMB}MB)');
      }
    }

    return diff;
  }

  /// 특정 이미지 작업의 메모리 사용량을 프로파일링합니다.
  ///
  /// [description]은 작업에 대한 설명입니다.
  /// [imageUrl]은 이미지 URL입니다.
  /// [action]은 프로파일링할 이미지 관련 작업입니다.
  /// [failTestOnLeak]이 true이고 누수가 감지되면 테스트가 실패합니다.
  /// [thresholdMB]는 누수로 간주할 임계값(MB)입니다.
  Future<MemoryDiff?> profileImageAction(
    String description,
    String imageUrl,
    Future<void> Function() action, {
    bool failTestOnLeak = false,
    int thresholdMB = 15, // 이미지 작업은 일반적으로 더 많은 메모리를 사용함
  }) async {
    final beforeLabel = 'test_image_${description}_before';
    final afterLabel = 'test_image_${description}_after';

    // 작업 전 스냅샷
    await takeMemorySnapshot(beforeLabel, metadata: {
      'type': 'test_image_action',
      'description': description,
      'imageUrl': imageUrl,
      'threshold_mb': thresholdMB,
    });

    // 작업 실행
    await action();

    // 프레임 처리 대기
    await pumpAndSettle();

    // GC 유도를 위한 지연
    await Future.delayed(const Duration(milliseconds: 500));

    // 작업 후 스냅샷
    await takeMemorySnapshot(afterLabel, metadata: {
      'type': 'test_image_action',
      'description': description,
      'imageUrl': imageUrl,
      'threshold_mb': thresholdMB,
    });

    // 메모리 차이 계산
    final diff = calculateMemoryDiff(beforeLabel, afterLabel);

    if (diff != null) {
      final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
      logger.i('테스트 이미지 작업 "$description"의 메모리 사용: ${heapDiffMB}MB');

      // 누수 감지 및 테스트 실패 처리
      if (failTestOnLeak && heapDiffMB > thresholdMB) {
        fail(
            '이미지 작업 메모리 누수 감지: 작업 "$description"에서 ${heapDiffMB}MB 메모리 증가 (임계값: ${thresholdMB}MB)');
      }
    }

    return diff;
  }

  /// 테스트 완료 후 메모리 프로파일링 결과 보고서를 생성합니다.
  ///
  /// [testName]은 테스트 이름입니다.
  /// [outputDirectory]는 보고서를 저장할 디렉토리입니다. null이면 임시 디렉토리에 저장합니다.
  /// [generateHtml]이 true면 HTML 보고서도 생성합니다.
  ///
  /// 반환값은 생성된 보고서 파일 경로입니다.
  Future<String?> generateMemoryReport(
    String testName, {
    String? outputDirectory,
    bool generateHtml = true,
  }) async {
    final snapshots = MemoryProfiler.instance.getAllSnapshots();

    if (snapshots.isEmpty) {
      logger.w('보고서 생성 실패: 스냅샷이 없습니다.');
      return null;
    }

    // 출력 디렉토리 설정
    final Directory reportDir;
    if (outputDirectory != null) {
      reportDir = Directory(outputDirectory);
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      reportDir = Directory('${tempDir.path}/memory_reports');
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }
    }

    // 파일 이름 설정
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${testName.replaceAll(' ', '_')}_$timestamp';

    // JSON 보고서 생성
    final jsonReportPath = await MemoryProfilerReportService.generateReport(
      snapshots: snapshots,
      includeStackTrace: true,
      fileName: '$fileName.json',
    );

    // HTML 보고서 생성
    String? htmlReportPath;
    if (generateHtml) {
      htmlReportPath = await MemoryProfilerReportService.generateHtmlReport(
        snapshots: snapshots,
        fileName: '$fileName.html',
      );

      if (htmlReportPath != null) {
        logger.i('HTML 메모리 보고서 생성 완료: $htmlReportPath');
      }
    }

    final reportPath = htmlReportPath ?? jsonReportPath;
    if (reportPath != null) {
      logger.i('메모리 프로파일링 보고서 생성 완료: $reportPath');
    }

    return reportPath;
  }

  /// 특정 테스트 실행 후 메모리 누수를 감지합니다.
  ///
  /// [thresholdMB]는 누수로 간주할 임계값(MB)입니다.
  /// [failTestOnLeak]이 true이고 누수가 감지되면 테스트가 실패합니다.
  ///
  /// 반환값은 감지된 메모리 누수 리스트입니다.
  Future<List<MemoryLeakReport>> detectMemoryLeaksAfterTest({
    int thresholdMB = 10,
    bool failTestOnLeak = true,
  }) async {
    // GC 유도를 위한 지연
    await Future.delayed(const Duration(milliseconds: 500));

    // 누수 감지
    final leaks =
        await MemoryProfiler.instance.detectLeaks(thresholdMB: thresholdMB);

    // 결과 로깅
    if (leaks.isEmpty) {
      logger.i('테스트 실행 후 메모리 누수가 감지되지 않았습니다.');
    } else {
      for (final leak in leaks) {
        logger.w(
            '테스트 중 메모리 누수 감지: [${leak.source}] ${leak.sizeMB}MB - ${leak.details}');
      }

      // 테스트 실패 처리
      if (failTestOnLeak && leaks.isNotEmpty) {
        final totalLeakMB =
            leaks.fold<int>(0, (sum, leak) => sum + leak.sizeMB);
        fail(
            '테스트 실행 중 총 ${leaks.length}개의 메모리 누수가 감지되었습니다. 총 누수 크기: ${totalLeakMB}MB');
      }
    }

    return leaks;
  }
}
