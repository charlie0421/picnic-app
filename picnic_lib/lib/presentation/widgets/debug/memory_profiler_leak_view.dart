import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart'
    hide MemoryLeakReport;
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';

/// 메모리 누수 감지 결과를 표시하는 위젯
class MemoryProfilerLeakView extends ConsumerWidget {
  const MemoryProfilerLeakView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilerState = ref.watch(memoryProfilerProvider);
    final leaks = profilerState.detectedLeaks;
    final isDetecting = profilerState.isDetecting;
    final notifier = ref.read(memoryProfilerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          _buildHeader(context, leaks, isDetecting, notifier),
          const SizedBox(height: 16),
          Expanded(
            child: isDetecting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.ltr,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('메모리 누수 감지 중...'),
                      ],
                    ),
                  )
                : leaks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.ltr,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '감지된 메모리 누수가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '누수 감지 버튼을 눌러 검사를 실행하세요',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildLeaksList(leaks),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<MemoryLeakReport> leaks,
    bool isDetecting,
    MemoryProfilerNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.ltr,
          children: [
            const Text(
              '메모리 누수 감지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: isDetecting
                  ? null
                  : () async {
                      await notifier.detectLeaks();
                      logger.i('메모리 누수 감지 실행');
                    },
              icon: Icon(
                isDetecting ? Icons.hourglass_top : Icons.search,
                size: 18,
              ),
              label: Text(isDetecting ? '감지 중...' : '누수 감지'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '감지된 잠재적 메모리 누수: ${leaks.length}개',
          style: TextStyle(
            color: leaks.isEmpty ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildLeaksList(List<MemoryLeakReport> leaks) {
    return ListView.builder(
      itemCount: leaks.length,
      itemBuilder: (context, index) {
        final leak = leaks[index];
        return _buildLeakItem(leak, context);
      },
    );
  }

  Widget _buildLeakItem(MemoryLeakReport leak, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          '[${leak.source}] ${leak.sizeMB}MB',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          leak.details,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDateTime(leak.timestamp),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.ltr,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '상세 정보:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(leak.details),
                const SizedBox(height: 16),
                if (leak.stackTrace != null && leak.stackTrace!.isNotEmpty) ...[
                  const Text(
                    '스택 트레이스:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      leak.stackTrace!.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  textDirection: TextDirection.ltr,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('해결 방법'),
                      onPressed: () {
                        _showSolutionDialog(context, leak);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSolutionDialog(BuildContext context, MemoryLeakReport leak) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('메모리 누수 해결 방법'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                Text('소스: ${leak.source}'),
                Text('크기: ${leak.sizeMB}MB'),
                const SizedBox(height: 16),
                const Text(
                  '가능한 해결 방법:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // 소스별 맞춤 해결 방법 제공
                ..._getSolutionsBySource(leak.source),
                const SizedBox(height: 16),
                const Text(
                  '일반적인 해결 방법:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• 이미지 사용 후 dispose 확인'),
                const Text('• 스트림 구독 취소 확인'),
                const Text('• 컨트롤러 dispose 확인'),
                const Text('• 메모리 캐시 크기 제한 확인'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _getSolutionsBySource(String source) {
    switch (source) {
      case 'ImageCache':
        return const [
          Text('• 이미지 캐시 크기 제한 설정'),
          Text('• 빠른 스크롤에서 이미지 로드 지연'),
          Text('• 사용하지 않는 이미지에 대해 evict 호출'),
        ];
      case 'ImageProcessing':
        return const [
          Text('• 이미지 크기 조정 및 다운샘플링 적용'),
          Text('• 메모리 효율적인 디코딩 옵션 사용'),
          Text('• 대용량 이미지를 메모리에 오래 유지하지 않기'),
        ];
      default:
        return const [
          Text('• 메모리 사용량이 큰 객체의 생명주기 확인'),
          Text('• 큰 컬렉션이나 리스트 사용 후 정리 확인'),
          Text('• 비동기 작업에서 컨텍스트 참조 확인'),
        ];
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
