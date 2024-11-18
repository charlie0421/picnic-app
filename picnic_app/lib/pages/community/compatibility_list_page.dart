import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_history_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityHistoryPage extends ConsumerStatefulWidget {
  const CompatibilityHistoryPage({super.key});

  @override
  ConsumerState<CompatibilityHistoryPage> createState() =>
      _CompatibilityHistoryPageState();
}

class _CompatibilityHistoryPageState
    extends ConsumerState<CompatibilityHistoryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
        () => ref.read(compatibilityHistoryProvider.notifier).loadInitial());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(compatibilityHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(compatibilityHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 궁합 기록'),
      ),
      body: history.items.isEmpty && !history.isLoading
          ? const Center(child: Text('아직 궁합 기록이 없습니다'))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: history.items.length + (history.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == history.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final item = history.items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getScoreColor(item.compatibilityScore ?? 0),
                      child: Text(
                        '${item.compatibilityScore}%',
                        style:
                            getTextStyle(AppTypo.caption12B, AppColors.grey00),
                      ),
                    ),
                    title: Text(item.artist.name['ko'] ?? ''),
                    subtitle: Text(
                      '${item.birthDate.year}년 ${item.birthDate.month}월 ${item.birthDate.day}일',
                    ),
                    trailing: Text(
                      _getStatusText(item.status),
                      style: getTextStyle(
                        AppTypo.caption12B,
                        _getStatusColor(item.status),
                      ),
                    ),
                    onTap: () {
                      // Navigate to result page
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.primary500;
    if (score >= 80) return AppColors.primary500;
    if (score >= 70) return AppColors.primary500;
    return AppColors.grey500;
  }

  Color _getStatusColor(CompatibilityStatus status) {
    return switch (status) {
      CompatibilityStatus.completed => AppColors.primary500,
      CompatibilityStatus.pending => AppColors.grey500,
      CompatibilityStatus.error => AppColors.point900,
    };
  }

  String _getStatusText(CompatibilityStatus status) {
    return switch (status) {
      CompatibilityStatus.completed => '완료',
      CompatibilityStatus.pending => '분석중',
      CompatibilityStatus.error => '오류',
    };
  }
}
