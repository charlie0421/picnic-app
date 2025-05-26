import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';

/// 메모리 스냅샷 목록과 상세 정보를 표시하는 위젯
class MemorySnapshotViewer extends ConsumerWidget {
  const MemorySnapshotViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = MemoryProfiler.instance.getAllSnapshots();

    if (snapshots.isEmpty) {
      return const Center(
        child: Text(
          '스냅샷이 없습니다',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // 최신 순으로 정렬
    final sortedSnapshots = snapshots.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.ltr,
            children: [
              const Text(
                '메모리 스냅샷',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '총 ${snapshots.length}개',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedSnapshots.length,
            itemBuilder: (context, index) {
              final snapshot = sortedSnapshots[index];
              return SnapshotListItem(
                snapshot: snapshot,
                onTap: () => _showSnapshotDetails(context, snapshot),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSnapshotDetails(BuildContext context, MemorySnapshot snapshot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SnapshotDetailsView(
            snapshot: snapshot,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// 스냅샷 목록 아이템 위젯
class SnapshotListItem extends StatelessWidget {
  final MemorySnapshot snapshot;
  final VoidCallback onTap;

  const SnapshotListItem({
    super.key,
    required this.snapshot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = snapshot.metadata['level'] as int? ??
        MemoryProfiler.snapshotLevelMedium;
    final heapSizeMB = snapshot.heapUsage.used ~/ (1024 * 1024);
    final imageSizeMB = snapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [
                  Flexible(
                    child: Text(
                      snapshot.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(level),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDateTime(snapshot.timestamp),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [
                  Text('힙: ${heapSizeMB}MB'),
                  Text('이미지 캐시: ${imageSizeMB}MB'),
                  Text('이미지 수: ${snapshot.imageCacheStats.liveImages}개'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case MemoryProfiler.snapshotLevelLow:
        return Colors.grey;
      case MemoryProfiler.snapshotLevelMedium:
        return Colors.blue;
      case MemoryProfiler.snapshotLevelHigh:
        return Colors.orange;
      case MemoryProfiler.snapshotLevelCritical:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

/// 스냅샷 상세 정보 화면
class SnapshotDetailsView extends StatelessWidget {
  final MemorySnapshot snapshot;
  final ScrollController scrollController;

  const SnapshotDetailsView({
    super.key,
    required this.snapshot,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final level = snapshot.metadata['level'] as int? ??
        MemoryProfiler.snapshotLevelMedium;
    final stackTrace = snapshot.metadata['stackTrace'] as List<String>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '스냅샷 상세 정보',
          style: TextStyle(
            color: _getLevelColor(level),
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection('기본 정보', [
            _buildInfoRow('레이블', snapshot.label),
            _buildInfoRow('생성 시간', _formatDateTime(snapshot.timestamp)),
            _buildInfoRow(
              '중요도',
              _getLevelName(level),
              valueColor: _getLevelColor(level),
            ),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('메모리 사용량', [
            _buildInfoRow(
              '힙 사용량',
              '${snapshot.heapUsage.used ~/ (1024 * 1024)}MB / ${snapshot.heapUsage.capacity ~/ (1024 * 1024)}MB',
            ),
            _buildInfoRow(
              '이미지 캐시',
              '${snapshot.imageCacheStats.sizeBytes ~/ (1024 * 1024)}MB (${snapshot.imageCacheStats.liveImages}개)',
            ),
            if (snapshot.heapUsage.external > 0)
              _buildInfoRow(
                '외부 메모리',
                '${snapshot.heapUsage.external ~/ (1024 * 1024)}MB',
              ),
          ]),
          if (snapshot.metadata.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoSection(
              '메타데이터',
              snapshot.metadata.entries
                  .where((e) => e.key != 'level' && e.key != 'stackTrace')
                  .map((e) => _buildInfoRow(e.key, e.value.toString()))
                  .toList(),
            ),
          ],
          if (stackTrace != null && stackTrace.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStackTraceSection('스택 트레이스', stackTrace),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackTraceSection(String title, List<String> stackTrace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            stackTrace.join('\n'),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case MemoryProfiler.snapshotLevelLow:
        return Colors.grey;
      case MemoryProfiler.snapshotLevelMedium:
        return Colors.blue;
      case MemoryProfiler.snapshotLevelHigh:
        return Colors.orange;
      case MemoryProfiler.snapshotLevelCritical:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _getLevelName(int level) {
    switch (level) {
      case MemoryProfiler.snapshotLevelLow:
        return '낮음';
      case MemoryProfiler.snapshotLevelMedium:
        return '중간';
      case MemoryProfiler.snapshotLevelHigh:
        return '높음';
      case MemoryProfiler.snapshotLevelCritical:
        return '심각';
      default:
        return '알 수 없음';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
