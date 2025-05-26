import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/services/memory_profiler_report_service.dart';
import 'package:share_plus/share_plus.dart';

/// 메모리 프로파일러 설정 위젯
class MemoryProfilerSettings extends ConsumerWidget {
  const MemoryProfilerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilerState = ref.watch(memoryProfilerProvider);
    final settings = profilerState.settings;
    final notifier = ref.read(memoryProfilerProvider.notifier);

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.ltr,
          children: [
            const Text(
              '메모리 프로파일러 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 자동 스냅샷 설정
            SwitchListTile(
              title: const Text('자동 스냅샷'),
              subtitle: const Text('일정 간격으로 메모리 스냅샷을 자동 생성합니다'),
              value: settings.enableAutoSnapshot,
              onChanged: (value) {
                notifier.setAutoSnapshotEnabled(value);
                logger.i('자동 스냅샷 ${value ? "활성화" : "비활성화"}');
              },
            ),

            // 자동 스냅샷 간격 설정
            if (settings.enableAutoSnapshot) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.ltr,
                  children: [
                    const Text('자동 스냅샷 간격'),
                    Material(
                      type: MaterialType.transparency,
                      child: DropdownButton<int>(
                        value: settings.autoSnapshotIntervalSeconds,
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10초')),
                          DropdownMenuItem(value: 30, child: Text('30초')),
                          DropdownMenuItem(value: 60, child: Text('1분')),
                          DropdownMenuItem(value: 300, child: Text('5분')),
                          DropdownMenuItem(value: 600, child: Text('10분')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            notifier.setAutoSnapshotInterval(value);
                            logger.i('자동 스냅샷 간격 설정: $value초');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 누수 감지 임계값 설정
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [
                  const Text('메모리 누수 감지 임계값'),
                  Material(
                    type: MaterialType.transparency,
                    child: DropdownButton<int>(
                      value: settings.minimumLeakThresholdMB,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5MB')),
                        DropdownMenuItem(value: 10, child: Text('10MB')),
                        DropdownMenuItem(value: 20, child: Text('20MB')),
                        DropdownMenuItem(value: 50, child: Text('50MB')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                                  .read(memoryProfilerSettingsProvider.notifier)
                                  .state =
                              settings.copyWith(minimumLeakThresholdMB: value);
                          logger.i('메모리 누수 감지 임계값 설정: ${value}MB');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 스냅샷 관리 섹션
            const Text(
              '스냅샷 관리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 작업 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  label: '스냅샷 생성',
                  icon: Icons.add_a_photo,
                  onPressed: () {
                    final label =
                        'manual_${DateTime.now().millisecondsSinceEpoch}';
                    notifier.takeSnapshot(
                      label,
                      level: MemoryProfiler.snapshotLevelHigh,
                      includeStackTrace: true,
                    );
                    logger.i('수동 스냅샷 생성: $label');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('스냅샷이 생성되었습니다')),
                    );
                  },
                ),
                _buildActionButton(
                  label: '누수 감지',
                  icon: Icons.search,
                  onPressed: () async {
                    await notifier.detectLeaks();
                    logger.i('메모리 누수 감지 실행');
                    final leakCount = profilerState.detectedLeaks.length;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$leakCount개의 잠재적 메모리 누수가 감지되었습니다'),
                        backgroundColor:
                            leakCount > 0 ? Colors.red : Colors.green,
                      ),
                    );
                  },
                  isLoading: profilerState.isDetecting,
                ),
                _buildActionButton(
                  label: 'GC 유도',
                  icon: Icons.cleaning_services,
                  onPressed: () async {
                    // 빈 작업을 실행하여 GC 유도
                    await MemoryProfiler.instance.profileAction(
                      'manual_gc',
                      () async {
                        // 빈 작업
                        await Future.delayed(const Duration(milliseconds: 100));
                      },
                      level: MemoryProfiler.snapshotLevelMedium,
                    );
                    logger.i('가비지 컬렉션 유도 시도');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('가비지 컬렉션 유도를 시도했습니다')),
                    );
                  },
                ),
                _buildActionButton(
                  label: '보고서 생성',
                  icon: Icons.assessment,
                  onPressed: () async {
                    final snapshots = MemoryProfiler.instance.getAllSnapshots();
                    if (snapshots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('스냅샷이 없어 보고서를 생성할 수 없습니다')),
                      );
                      return;
                    }

                    // 보고서 생성 중 다이얼로그 표시
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('메모리 프로파일링 보고서 생성 중...'),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      // HTML 보고서 생성
                      final reportPath =
                          await MemoryProfilerReportService.generateHtmlReport(
                        snapshots: snapshots,
                      );

                      // 다이얼로그 닫기
                      if (context.mounted) Navigator.of(context).pop();

                      if (reportPath != null) {
                        // 보고서 공유
                        await Share.shareXFiles(
                          [XFile(reportPath)],
                          text: '메모리 프로파일링 보고서',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('보고서가 생성되었습니다')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('보고서 생성에 실패했습니다'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      logger.e('보고서 생성 중 오류', error: e);

                      // 다이얼로그 닫기
                      if (context.mounted) Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('보고서 생성 중 오류 발생: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                _buildActionButton(
                  label: '스냅샷 초기화',
                  icon: Icons.delete,
                  onPressed: () {
                    MemoryProfiler.instance.clearSnapshots();
                    logger.i('모든 스냅샷이 초기화되었습니다');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 스냅샷이 초기화되었습니다')),
                    );
                  },
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 도움말 섹션
            const ExpansionTile(
              title: Text('도움말 및 팁'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.ltr,
                    children: [
                      Text('• 메모리 프로파일러는 디버그 모드에서만 활성화됩니다.'),
                      SizedBox(height: 8),
                      Text('• 자동 스냅샷은 앱 사용 중 주기적으로 메모리 상태를 기록합니다.'),
                      SizedBox(height: 8),
                      Text(
                          '• 스냅샷을 생성한 후 화면 이동, 이미지 로드 등의 작업 후 다시 스냅샷을 생성하여 메모리 변화를 확인할 수 있습니다.'),
                      SizedBox(height: 8),
                      Text(
                          '• 누수 감지 기능은 임계값 이상으로 메모리 사용량이 증가한 경우를 잠재적 누수로 감지합니다.'),
                      SizedBox(height: 8),
                      Text(
                          '• GC 유도 기능은 가비지 컬렉션을 간접적으로 요청하는 기능으로, 즉시 실행을 보장하지는 않습니다.'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color != null ? Colors.white : null,
      ),
    );
  }
}
