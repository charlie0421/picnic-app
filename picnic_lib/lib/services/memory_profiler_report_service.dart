import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';

/// 메모리 프로파일링 보고서 생성 서비스
class MemoryProfilerReportService {
  /// 메모리 스냅샷 데이터를 기반으로 보고서를 생성하고 저장합니다.
  ///
  /// [snapshots]은 분석할 메모리 스냅샷 목록입니다.
  /// [includeStackTrace]가 true이면 스택 트레이스 정보를 포함합니다.
  /// [fileName]은 보고서 파일의 이름입니다. 기본값은 현재 타임스탬프를 사용합니다.
  ///
  /// 반환값은 저장된 보고서 파일의 경로입니다.
  static Future<String?> generateReport({
    required List<MemorySnapshot> snapshots,
    bool includeStackTrace = true,
    String? fileName,
  }) async {
    if (snapshots.isEmpty) {
      logger.w('보고서 생성 실패: 스냅샷이 없습니다.');
      return null;
    }

    try {
      // 보고서 데이터 생성
      final reportData = _buildReportData(snapshots, includeStackTrace);

      // 웹 환경에서는 파일 저장 불가능하므로 문자열만 반환
      if (kIsWeb) {
        logger.i('웹 환경에서는 보고서를 파일로 저장할 수 없습니다.');
        return jsonEncode(reportData);
      }

      // 파일명 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reportFileName = fileName ?? 'memory_report_$timestamp.json';

      // 문서 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/memory_reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // 보고서 파일 저장
      final file = File('${reportsDir.path}/$reportFileName');
      await file.writeAsString(jsonEncode(reportData));

      logger.i('메모리 프로파일링 보고서가 생성되었습니다: ${file.path}');
      return file.path;
    } catch (e, s) {
      logger.e('보고서 생성 중 오류 발생', error: e, stackTrace: s);
      return null;
    }
  }

  /// 보고서 형식으로 데이터 변환
  static Map<String, dynamic> _buildReportData(
    List<MemorySnapshot> snapshots,
    bool includeStackTrace,
  ) {
    // 스냅샷 정렬 (최신순)
    final sortedSnapshots = List<MemorySnapshot>.from(snapshots)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 스냅샷 데이터 추출
    final snapshotsData = sortedSnapshots.map((snapshot) {
      return {
        'label': snapshot.label,
        'timestamp': snapshot.timestamp.toIso8601String(),
        'heapUsage': {
          'used': snapshot.heapUsage.used,
          'usedMB': snapshot.heapUsage.used ~/ (1024 * 1024),
          'capacity': snapshot.heapUsage.capacity,
          'capacityMB': snapshot.heapUsage.capacity ~/ (1024 * 1024),
          'external': snapshot.heapUsage.external,
          'externalMB': snapshot.heapUsage.external ~/ (1024 * 1024),
        },
        'imageCache': {
          'liveImages': snapshot.imageCacheStats.liveImages,
          'sizeBytes': snapshot.imageCacheStats.sizeBytes,
          'sizeMB': snapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024),
        },
        'metadata': {
          ...snapshot.metadata,
          if (!includeStackTrace) 'stackTrace': null,
        },
      };
    }).toList();

    // 메모리 사용 트렌드 분석
    final memoryTrends = _analyzeMemoryTrends(sortedSnapshots);

    // 메모리 누수 의심 지점 분석
    final leakSuspicions = _analyzeLeakSuspicions(sortedSnapshots);

    // 최종 보고서 데이터
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'snapshotCount': snapshots.length,
      'timeRange': {
        'start': sortedSnapshots.last.timestamp.toIso8601String(),
        'end': sortedSnapshots.first.timestamp.toIso8601String(),
      },
      'summary': {
        'initialHeapMB': sortedSnapshots.last.heapUsage.used ~/ (1024 * 1024),
        'finalHeapMB': sortedSnapshots.first.heapUsage.used ~/ (1024 * 1024),
        'maxHeapMB': sortedSnapshots
            .map((s) => s.heapUsage.used ~/ (1024 * 1024))
            .reduce((a, b) => a > b ? a : b),
        'initialImageCacheMB':
            sortedSnapshots.last.imageCacheStats.sizeBytes ~/ (1024 * 1024),
        'finalImageCacheMB':
            sortedSnapshots.first.imageCacheStats.sizeBytes ~/ (1024 * 1024),
        'maxImageCacheMB': sortedSnapshots
            .map((s) => s.imageCacheStats.sizeBytes ~/ (1024 * 1024))
            .reduce((a, b) => a > b ? a : b),
      },
      'memoryTrends': memoryTrends,
      'leakSuspicions': leakSuspicions,
      'snapshots': snapshotsData,
    };
  }

  /// 메모리 사용 트렌드 분석
  static List<Map<String, dynamic>> _analyzeMemoryTrends(
    List<MemorySnapshot> snapshots,
  ) {
    if (snapshots.length < 2) return [];

    final trends = <Map<String, dynamic>>[];

    // 시간 순서로 정렬 (오래된 것부터)
    final chronologicalSnapshots = List<MemorySnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 1; i < chronologicalSnapshots.length; i++) {
      final before = chronologicalSnapshots[i - 1];
      final after = chronologicalSnapshots[i];

      // 시간 차이 계산 (밀리초)
      final timeDiffMs =
          after.timestamp.difference(before.timestamp).inMilliseconds;

      // 힙 메모리 변화량 계산 (MB)
      final heapDiffMB =
          (after.heapUsage.used - before.heapUsage.used) ~/ (1024 * 1024);

      // 이미지 캐시 변화량 계산 (MB)
      final imageCacheDiffMB = (after.imageCacheStats.sizeBytes -
              before.imageCacheStats.sizeBytes) ~/
          (1024 * 1024);

      // 이미지 개수 변화량
      final imageCountDiff =
          after.imageCacheStats.liveImages - before.imageCacheStats.liveImages;

      // 초당 변화량 계산 (MB/s)
      final heapChangeRatePerSecond =
          timeDiffMs > 0 ? (heapDiffMB * 1000 / timeDiffMs) : 0;
      final imageCacheChangeRatePerSecond =
          timeDiffMs > 0 ? (imageCacheDiffMB * 1000 / timeDiffMs) : 0;

      // 트렌드 데이터 추가
      trends.add({
        'fromSnapshot': before.label,
        'toSnapshot': after.label,
        'timeDiffMs': timeDiffMs,
        'heapChangeMB': heapDiffMB,
        'heapChangeRate': heapChangeRatePerSecond,
        'imageCacheChangeMB': imageCacheDiffMB,
        'imageCacheChangeRate': imageCacheChangeRatePerSecond,
        'imageCountChange': imageCountDiff,
      });
    }

    return trends;
  }

  /// 메모리 누수 의심 지점 분석
  static List<Map<String, dynamic>> _analyzeLeakSuspicions(
    List<MemorySnapshot> snapshots,
  ) {
    if (snapshots.length < 2) return [];

    final suspicions = <Map<String, dynamic>>[];
    final threshold = 10; // 누수 의심 임계값 (MB)

    // 시간 순서로 정렬 (오래된 것부터)
    final chronologicalSnapshots = List<MemorySnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 1; i < chronologicalSnapshots.length; i++) {
      final before = chronologicalSnapshots[i - 1];
      final after = chronologicalSnapshots[i];

      // 힙 메모리 증가량 (MB)
      final heapIncreaseMB =
          (after.heapUsage.used - before.heapUsage.used) ~/ (1024 * 1024);

      // 임계값을 초과하는 메모리 증가가 있으면 의심 지점으로 기록
      if (heapIncreaseMB > threshold) {
        final timeDiff = after.timestamp.difference(before.timestamp);
        final source = after.metadata['type'] ?? 'unknown';

        suspicions.add({
          'fromSnapshot': before.label,
          'toSnapshot': after.label,
          'timeDiffMs': timeDiff.inMilliseconds,
          'heapIncreaseMB': heapIncreaseMB,
          'source': source,
          'severity': heapIncreaseMB > threshold * 2 ? 'high' : 'medium',
          'details':
              '스냅샷 ${before.label}과 ${after.label} 사이에 ${heapIncreaseMB}MB의 메모리 증가 발생',
          'recommendation': _getRecommendation(source, heapIncreaseMB),
        });
      }
    }

    return suspicions;
  }

  /// 누수 소스에 따른 권장 사항
  static String _getRecommendation(String source, int increaseMB) {
    switch (source) {
      case 'image_operation':
        return '이미지 작업 후 메모리가 ${increaseMB}MB 증가했습니다. '
            '이미지 캐시를 제한하고, 큰 이미지는 다운샘플링하며, 사용 후 이미지 레퍼런스를 해제하세요.';

      case 'route_change':
        return '화면 전환 후 메모리가 ${increaseMB}MB 증가했습니다. '
            '이전 화면의 컨트롤러와 스트림 구독이 제대로 dispose 되었는지 확인하세요.';

      default:
        return '${increaseMB}MB의 메모리 증가가 감지되었습니다. '
            '컨트롤러 dispose, 이벤트 리스너 해제, 대용량 객체 레퍼런스 제거를 확인하세요.';
    }
  }

  /// HTML 형식의 보고서 생성
  static Future<String?> generateHtmlReport({
    required List<MemorySnapshot> snapshots,
    String? fileName,
  }) async {
    if (snapshots.isEmpty) {
      logger.w('HTML 보고서 생성 실패: 스냅샷이 없습니다.');
      return null;
    }

    try {
      // 보고서 데이터 생성
      final reportData = _buildReportData(snapshots, true);

      // HTML 문자열 생성
      final htmlContent = _generateHtmlContent(reportData);

      // 웹 환경에서는 파일 저장 불가능하므로 HTML 문자열만 반환
      if (kIsWeb) {
        logger.i('웹 환경에서는 보고서를 파일로 저장할 수 없습니다.');
        return htmlContent;
      }

      // 파일명 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reportFileName = fileName ?? 'memory_report_$timestamp.html';

      // 문서 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/memory_reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // HTML 보고서 파일 저장
      final file = File('${reportsDir.path}/$reportFileName');
      await file.writeAsString(htmlContent);

      logger.i('HTML 메모리 프로파일링 보고서가 생성되었습니다: ${file.path}');
      return file.path;
    } catch (e, s) {
      logger.e('HTML 보고서 생성 중 오류 발생', error: e, stackTrace: s);
      return null;
    }
  }

  /// HTML 보고서 내용 생성
  static String _generateHtmlContent(Map<String, dynamic> reportData) {
    final generatedAt = reportData['generatedAt'];
    final snapshotCount = reportData['snapshotCount'];
    final summary = reportData['summary'];
    final trends = reportData['memoryTrends'];
    final leakSuspicions = reportData['leakSuspicions'];

    // HTML 헤더
    final html = '''
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>메모리 프로파일링 보고서</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        h1, h2, h3 { color: #333; }
        .container { max-width: 1200px; margin: 0 auto; }
        .summary-box { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .leak-high { background-color: #ffdddd; }
        .leak-medium { background-color: #ffffdd; }
        .footer { margin-top: 30px; font-size: 0.8em; color: #666; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>메모리 프로파일링 보고서</h1>
        <p>생성 시간: $generatedAt | 스냅샷 수: $snapshotCount</p>
        
        <h2>요약</h2>
        <div class="summary-box">
          <p>초기 힙 메모리: ${summary['initialHeapMB']}MB → 최종 힙 메모리: ${summary['finalHeapMB']}MB (최대: ${summary['maxHeapMB']}MB)</p>
          <p>초기 이미지 캐시: ${summary['initialImageCacheMB']}MB → 최종 이미지 캐시: ${summary['finalImageCacheMB']}MB (최대: ${summary['maxImageCacheMB']}MB)</p>
          <p>메모리 변화량: ${summary['finalHeapMB'] - summary['initialHeapMB']}MB</p>
        </div>
        
        <h2>메모리 누수 의심 지점</h2>
    ''';

    // 누수 의심 테이블
    final leaksHtml = leakSuspicions.isEmpty
        ? '<p>감지된 메모리 누수 의심 지점이 없습니다.</p>'
        : '''
        <table>
          <tr>
            <th>시작 스냅샷</th>
            <th>종료 스냅샷</th>
            <th>증가량 (MB)</th>
            <th>소요 시간</th>
            <th>소스</th>
            <th>심각도</th>
            <th>권장 사항</th>
          </tr>
          ${leakSuspicions.map((leak) => '''
          <tr class="leak-${leak['severity']}">
            <td>${leak['fromSnapshot']}</td>
            <td>${leak['toSnapshot']}</td>
            <td>${leak['heapIncreaseMB']}</td>
            <td>${(leak['timeDiffMs'] / 1000).toStringAsFixed(2)}초</td>
            <td>${leak['source']}</td>
            <td>${leak['severity'] == 'high' ? '높음' : '중간'}</td>
            <td>${leak['recommendation']}</td>
          </tr>
          ''').join('')}
        </table>
        ''';

    // 메모리 트렌드 테이블
    final trendsHtml = trends.isEmpty
        ? '<p>메모리 트렌드 데이터가 부족합니다.</p>'
        : '''
        <h2>메모리 사용 트렌드</h2>
        <table>
          <tr>
            <th>시작 스냅샷</th>
            <th>종료 스냅샷</th>
            <th>힙 변화 (MB)</th>
            <th>변화율 (MB/s)</th>
            <th>이미지 캐시 변화 (MB)</th>
            <th>이미지 개수 변화</th>
            <th>소요 시간</th>
          </tr>
          ${trends.map((trend) => '''
          <tr>
            <td>${trend['fromSnapshot']}</td>
            <td>${trend['toSnapshot']}</td>
            <td>${trend['heapChangeMB']}</td>
            <td>${trend['heapChangeRate'].toStringAsFixed(2)}</td>
            <td>${trend['imageCacheChangeMB']}</td>
            <td>${trend['imageCountChange']}</td>
            <td>${(trend['timeDiffMs'] / 1000).toStringAsFixed(2)}초</td>
          </tr>
          ''').join('')}
        </table>
        ''';

    // 푸터와 HTML 닫기
    final footerHtml = '''
        <div class="footer">
          <p>이 보고서는 메모리 프로파일러에 의해 자동 생성되었습니다.</p>
        </div>
      </div>
    </body>
    </html>
    ''';

    return html + leaksHtml + trendsHtml + footerHtml;
  }
}
