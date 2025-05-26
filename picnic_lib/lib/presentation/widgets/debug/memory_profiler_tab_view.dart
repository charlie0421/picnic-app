import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_profiler_leak_view.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_snapshot_viewer.dart';

/// 메모리 프로파일러 탭 정보
class _TabInfo {
  final String label;
  final IconData icon;

  const _TabInfo({
    required this.label,
    required this.icon,
  });
}

/// 메모리 프로파일러 탭 선택 상태 관리
final memoryProfilerTabProvider = StateProvider<int>((ref) => 0);

/// 메모리 프로파일러 탭 뷰
class MemoryProfilerTabView extends ConsumerWidget {
  const MemoryProfilerTabView({super.key});

  static const List<_TabInfo> _tabs = [
    _TabInfo(label: '사용량', icon: Icons.memory),
    _TabInfo(label: '스냅샷', icon: Icons.camera_alt),
    _TabInfo(label: '누수감지', icon: Icons.bug_report),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(memoryProfilerTabProvider);

    return Column(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 탭 바
        _buildTabBar(context, ref, selectedTab),

        // 탭 콘텐츠
        Flexible(
          child: IndexedStack(
            index: selectedTab,
            children: [
              // 메모리 사용량 탭
              const _MemoryUsageView(),

              // 스냅샷 탭
              const MemorySnapshotViewer(),

              // 누수 감지 탭
              const MemoryProfilerLeakView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    WidgetRef ref,
    int selectedTab,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedTab;

          return _buildTabItem(
            context,
            tab: tab,
            isSelected: isSelected,
            onTap: () =>
                ref.read(memoryProfilerTabProvider.notifier).state = index,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required _TabInfo tab,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 16,
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 메모리 사용량 표시 뷰
class _MemoryUsageView extends ConsumerWidget {
  const _MemoryUsageView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilerState = ref.watch(memoryProfilerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메모리 프로파일러 상태
          _buildMemoryCard(
            context,
            title: '프로파일러 상태',
            value: profilerState.isEnabled ? '활성화' : '비활성화',
            icon: Icons.memory,
            color: profilerState.isEnabled ? Colors.green : Colors.grey,
          ),

          const SizedBox(height: 12),

          // 누수 감지 상태
          _buildMemoryCard(
            context,
            title: '누수 감지',
            value: profilerState.isDetecting ? '진행 중' : '대기 중',
            icon: Icons.bug_report,
            color: profilerState.isDetecting ? Colors.orange : Colors.blue,
          ),

          const SizedBox(height: 12),

          // 감지된 누수 개수
          _buildMemoryCard(
            context,
            title: '감지된 누수',
            value: '${profilerState.detectedLeaks.length}개',
            icon: Icons.warning,
            color: profilerState.detectedLeaks.isNotEmpty
                ? Colors.red
                : Colors.green,
          ),

          const SizedBox(height: 16),

          // 컨트롤 버튼들
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(memoryProfilerProvider.notifier).takeSnapshot(
                          'manual_${DateTime.now().millisecondsSinceEpoch}',
                        );
                  },
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('스냅샷', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: profilerState.isDetecting
                      ? null
                      : () {
                          ref
                              .read(memoryProfilerProvider.notifier)
                              .detectLeaks();
                        },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('누수 감지', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 자동 스냅샷 설정
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '자동 스냅샷: ${profilerState.settings.enableAutoSnapshot ? "활성화" : "비활성화"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Switch(
                  value: profilerState.settings.enableAutoSnapshot,
                  onChanged: (value) {
                    ref
                        .read(memoryProfilerProvider.notifier)
                        .setAutoSnapshotEnabled(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
