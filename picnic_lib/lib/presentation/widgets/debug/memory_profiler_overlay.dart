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

    // 오버레이가 표시되지 않는 경우에는 원래 위젯 반환
    // (토글 버튼만 표시)
    if (!isOverlayVisible) {
      return Stack(
        alignment: Alignment.topLeft,
        textDirection: TextDirection.ltr,
        children: [
          child,
          Positioned(
            right: 10,
            bottom: 60,
            child: _buildToggleButton(ref),
          ),
        ],
      );
    }

    // 오버레이가 표시되는 경우 (전체 오버레이 + 토글 버튼)
    return Stack(
      alignment: Alignment.topLeft,
      textDirection: TextDirection.ltr,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 150,
          child: _buildMemoryInfoPanel(profilerState),
        ),
        Positioned(
          right: 10,
          bottom: 60,
          child: _buildActionButtons(ref),
        ),
      ],
    );
  }

  Widget _buildToggleButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(memoryProfilerOverlayVisibleProvider.notifier).state = true;
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(
          Icons.memory,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOverlayPanel(
    BuildContext context,
    WidgetRef ref,
    MemoryProfilerState profilerState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(-3, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          _buildOverlayHeader(context, ref),
          const Expanded(
            child: MemoryProfilerTabView(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.ltr,
        children: [
          const Row(
            textDirection: TextDirection.ltr,
            children: [
              Icon(
                Icons.memory,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '메모리 프로파일러',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ref.read(memoryProfilerOverlayVisibleProvider.notifier).state =
                  false;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryInfoPanel(MemoryProfilerState profilerState) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          const Text(
            '메모리 사용량',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              const Icon(
                Icons.memory,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '힙: ${_formatMemorySize(0)} MB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.image,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '이미지 캐시: ${_formatMemorySize(PaintingBinding.instance.imageCache.currentSizeBytes ~/ (1024 * 1024))} MB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '이미지 개수: ${PaintingBinding.instance.imageCache.liveImageCount}개 / 캐시 히트: ${PaintingBinding.instance.imageCache.currentSize}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemorySize(int sizeInMB) {
    if (sizeInMB < 1000) {
      return '$sizeInMB';
    } else {
      return '${(sizeInMB / 1000).toStringAsFixed(1)}K';
    }
  }

  Widget _buildActionButtons(WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        _buildActionButton(
          icon: Icons.cleaning_services,
          color: Colors.amber,
          onTap: () {
            // 이미지 캐시 정리
            final previousSize =
                PaintingBinding.instance.imageCache.currentSizeBytes;
            PaintingBinding.instance.imageCache.clear();
            logger.i(
                '이미지 캐시 정리: ${(previousSize / (1024 * 1024)).toStringAsFixed(1)}MB 해제');
          },
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.photo_camera,
          color: Colors.blue,
          onTap: () {
            // 스냅샷 생성
            ref.read(memoryProfilerProvider.notifier).takeSnapshot(
                'manual_${DateTime.now().millisecondsSinceEpoch}',
                level: MemoryProfiler.snapshotLevelHigh);
          },
        ),
        const SizedBox(height: 8),
        _buildToggleButton(ref),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
