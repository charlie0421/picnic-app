import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/pages/community/compatibility_input_page.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_history_provider.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompatibilityHistoryPage extends ConsumerStatefulWidget {
  const CompatibilityHistoryPage({super.key, this.artistId});

  final int? artistId;

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
    Future.microtask(() => ref
        .read(compatibilityListProvider(artistId: widget.artistId).notifier)
        .loadInitial());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(compatibilityListProvider(artistId: widget.artistId).notifier)
          .loadMore();
    }
  }

  void _onNewCompatibilityTap() {
    final currentArtist = ref.read(communityStateInfoProvider).currentArtist;
    ref.read(navigationInfoProvider.notifier).setCurrentPage(
          CompatibilityInputPage(artist: currentArtist!),
        );
  }

  Widget _buildAnalysisTimeInfo(CompatibilityModel item) {
    if (item.hasError) {
      return Text(
        '분석 실패',
        style: getTextStyle(AppTypo.caption12R, AppColors.point900),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.createdAt != null) ...[
          Text(
            '분석: ${formatDateTimeYYYYMMDDHHM(item.createdAt!)}',
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
          const SizedBox(height: 2),
        ],
        if (item.isPending && item.createdAt != null) ...[
          Text(
            '${timeago.format(item.createdAt!, locale: 'ko')}부터 분석 중',
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final history =
        ref.watch(compatibilityListProvider(artistId: widget.artistId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F9), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Empty state or List
            history.items.isEmpty && !history.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '첫 궁합을 확인해보세요! 🌟',
                          style:
                              getTextStyle(AppTypo.body16B, AppColors.grey900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '당신과 잘 맞는 아티스트를 찾아보세요',
                          style:
                              getTextStyle(AppTypo.body14R, AppColors.grey600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount:
                        history.items.length + (history.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == history.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final item = history.items[index];
                      return InkWell(
                        onTap: () {
                          ref
                              .read(navigationInfoProvider.notifier)
                              .setCurrentPage(
                                CompatibilityResultPage(compatibility: item),
                              );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Artist Image with decorative border
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary500,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: item.artist.image != null
                                        ? PicnicCachedNetworkImage(
                                            imageUrl: item.artist.image!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            color: AppColors.grey100,
                                            child: Icon(
                                              Icons.person,
                                              color: AppColors.grey300,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.artist.name['ko'] ?? '',
                                              style: getTextStyle(
                                                AppTypo.body16B,
                                                AppColors.grey900,
                                              ),
                                            ),
                                          ),
                                          _buildStatusBadge(item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${item.birthDate.year}년 ${item.birthDate.month}월 ${item.birthDate.day}일',
                                        style: getTextStyle(
                                          AppTypo.body14R,
                                          AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildAnalysisTimeInfo(item),
                                      if (item.compatibilityScore != null) ...[
                                        const SizedBox(height: 8),
                                        _buildScoreBadge(
                                            item.compatibilityScore!),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            if (widget.artistId != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onNewCompatibilityTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '새로운 궁합 확인하기',
                          style: getTextStyle(AppTypo.body16B, Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CompatibilityStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: getTextStyle(
          AppTypo.caption12B,
          _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(score),
            _getScoreColor(score).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(score).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${score}% 일치',
        style: getTextStyle(AppTypo.caption12B, Colors.white),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFFFF4B8B); // 진한 핑크
    if (score >= 80) return const Color(0xFFFF6B9F); // 중간 핑크
    if (score >= 70) return const Color(0xFFFF8FB3); // 연한 핑크
    return AppColors.grey500;
  }

  Color _getStatusColor(CompatibilityStatus status) {
    return switch (status) {
      CompatibilityStatus.completed => const Color(0xFFFF4B8B),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
