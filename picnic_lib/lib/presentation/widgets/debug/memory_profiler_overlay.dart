import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/presentation/widgets/debug/memory_profiler_tab_view.dart';

/// 메모리 프로파일러 오버레이 표시 여부를 제어하는 프로바이더
final memoryProfilerOverlayVisibleProvider =
    StateProvider<bool>((ref) => false);

/// 메모리 프로파일링 결과를 화면에 표시하는 오버레이 위젯
class MemoryProfilerOverlay extends ConsumerWidget {
  final Widget child;

  const MemoryProfilerOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 디버그 모드가 아니면 오버레이를 표시하지 않음
    if (!kDebugMode) {
      return child;
    }

    // 메모리 프로파일러 상태 구독
    final profilerState = ref.watch(memoryProfilerProvider);
    final isOverlayVisible = ref.watch(memoryProfilerOverlayVisibleProvider);

    return Stack(
      children: [
        child,

        // 전체 프로파일러 오버레이 (오버레이가 열려있을 때만)
        if (isOverlayVisible)
          Positioned(
            left: 16,
            right: 16,
            top: 100,
            bottom: 120,
            child: SafeArea(
              child: _buildOverlayPanel(context, ref, profilerState),
            ),
          ),

        // 액션 버튼들 (항상 표시) - 더 안전한 위치
        Positioned(
          right: 8,
          bottom: 16,
          child: SafeArea(
            child: _buildActionButtons(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(WidgetRef ref) {
    final isOverlayVisible = ref.watch(memoryProfilerOverlayVisibleProvider);

    return GestureDetector(
      onTap: () {
        ref.read(memoryProfilerOverlayVisibleProvider.notifier).state =
            !isOverlayVisible;
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isOverlayVisible
              ? Colors.blue.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isOverlayVisible ? Colors.blue : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isOverlayVisible ? Colors.blue : Colors.white)
                  .withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.memory,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildOverlayPanel(
    BuildContext context,
    WidgetRef ref,
    MemoryProfilerState profilerState,
  ) {
    return Material(
      type: MaterialType.card,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOverlayHeader(context, ref),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                  ),
                  child: const MemoryProfilerTabView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayHeader(BuildContext context, WidgetRef ref) {
    final profilerState = ref.watch(memoryProfilerProvider);
    ref.watch(memoryProfilerOverlayVisibleProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목과 상태
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.memory,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '메모리 프로파일러',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '누수 감지: ${profilerState.detectedLeaks.length}개 | ${profilerState.isDetecting ? "분석 중..." : "대기 중"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 닫기 버튼
          Material(
            type: MaterialType.circle,
            color: Colors.grey[100],
            child: InkWell(
              onTap: () => ref
                  .read(memoryProfilerOverlayVisibleProvider.notifier)
                  .state = false,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.grey[700],
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 캐시 정리 버튼 (노란색 청소 아이콘)
          _buildSimpleButton(
            icon: Icons.cleaning_services,
            color: Colors.amber,
            onTap: () {
              // 이미지 캐시 정리
              final previousSize =
                  PaintingBinding.instance.imageCache.currentSizeBytes;
              PaintingBinding.instance.imageCache.clear();
              logger.i(
                  '이미지 캐시 정리: ${(previousSize / (1024 * 1024)).toStringAsFixed(1)}MB 해제');

              // 안전한 스낵바 표시
              _showSafeSnackBar(context, '이미지 캐시 정리 완료');
            },
          ),
          const SizedBox(height: 6),

          // 메모리 스냅샷 생성 버튼 (파란색 카메라 아이콘)
          _buildSimpleButton(
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () {
              // 스냅샷 생성
              ref.read(memoryProfilerProvider.notifier).takeSnapshot(
                  'manual_${DateTime.now().millisecondsSinceEpoch}',
                  level: MemoryProfiler.snapshotLevelHigh);

              // 안전한 스낵바 표시
              _showSafeSnackBar(context, '메모리 스냅샷 생성 완료');
            },
          ),
          const SizedBox(height: 6),

          // 메인 토글 버튼 (메모리 프로파일러 열기/닫기)
          _buildToggleButton(ref),
        ],
      ),
    );
  }

  Widget _buildSimpleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  /// 스낵바 표시 메서드 (MaterialApp 내부에 있으므로 안전함)
  void _showSafeSnackBar(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 오류 발생 시 로그로만 출력
      logger.i('메모리 프로파일러: $message (스낵바 표시 실패: $e)');
    }
  }
}
