import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_profiler_leak_view.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_profiler_settings.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_snapshot_viewer.dart';

/// 메모리 프로파일러의 탭 선택 상태를 관리하는 프로바이더
final memoryProfilerTabProvider = StateProvider<int>((ref) => 0);

/// 메모리 프로파일러 탭 뷰 위젯
///
/// 스냅샷, 누수 감지, 설정 등의 탭으로 구성되어 있습니다.
class MemoryProfilerTabView extends ConsumerWidget {
  const MemoryProfilerTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(memoryProfilerTabProvider);

    return Column(
      textDirection: TextDirection.ltr,
      children: [
        // 탭 바
        _buildTabBar(context, ref, selectedTab),

        // 탭 콘텐츠
        Expanded(
          child: IndexedStack(
            index: selectedTab,
            children: [
              // 스냅샷 탭
              const MemorySnapshotViewer(),

              // 누수 감지 탭
              const MemoryProfilerLeakView(),

              // 설정 탭
              const MemoryProfilerSettings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, int selectedTab) {
    // 탭 정보 정의
    final tabs = [
      _TabInfo(
        icon: Icons.photo_library,
        label: '스냅샷',
        index: 0,
      ),
      _TabInfo(
        icon: Icons.warning_amber,
        label: '누수 감지',
        index: 1,
      ),
      _TabInfo(
        icon: Icons.settings,
        label: '설정',
        index: 2,
      ),
    ];

    return Container(
      height: 60,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        textDirection: TextDirection.ltr,
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab.index;
          return _buildTabItem(
            context,
            tab: tab,
            isSelected: isSelected,
            onTap: () =>
                ref.read(memoryProfilerTabProvider.notifier).state = tab.index,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              Icon(
                tab.icon,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 탭 정보 클래스
class _TabInfo {
  final IconData icon;
  final String label;
  final int index;

  _TabInfo({
    required this.icon,
    required this.label,
    required this.index,
  });
}
