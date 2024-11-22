import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/community/compatibility/animated_heart.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';

class CompatibilityResultCard extends ConsumerWidget {
  const CompatibilityResultCard({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (compatibility.compatibilityScore != null) ...[
            _buildScoreSection(compatibility.compatibilityScore!),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStatusBadge(compatibility.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfileImageContainer(
                  avatarUrl: compatibility.artist.image ?? '',
                  width: 70,
                  height: 70,
                  borderRadius: 10,
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 1.5,
                  ),
                ),
                const SizedBox(width: 16),
                const FancyPulsingHeart(
                  size: 60.0,
                  color: Color(0xFFFF4B8B),
                  duration: Duration(seconds: 2),
                ),
                const SizedBox(width: 16),
                ProfileImageContainer(
                  avatarUrl: ref.read(userInfoProvider
                          .select((value) => value.value?.avatarUrl)) ??
                      '',
                  width: 70,
                  height: 70,
                  borderRadius: 10,
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildProfileInfo(
                    AxisDirection.left,
                    getLocaleTextFromJson(
                      compatibility.artist.name,
                    ),
                    compatibility.artist.birthDate,
                    null,
                  ),
                ),
                const SizedBox(width: 110),
                Expanded(
                  child: _buildProfileInfo(
                    AxisDirection.right,
                    ref.read(userInfoProvider
                            .select((value) => value.value?.nickname)) ??
                        '',
                    compatibility.birthDate,
                    compatibility.birthTime,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _getScoreColor(score),
            _getScoreColor(score).withOpacity(0.5),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _getScoreMessage(score),
            style: getTextStyle(AppTypo.body14R, Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(AxisDirection direction, String name,
      DateTime? birthDate, String? birthTime) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: direction == AxisDirection.left
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
          textAlign: TextAlign.center,
        ),
        if (birthDate != null) ...[
          Row(
            mainAxisAlignment: direction == AxisDirection.left
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatDateTimeYYYYMMDD(birthDate),
                style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
              ),
              Text(
                convertKoreanTraditionalTime(birthTime),
                style: getTextStyle(AppTypo.body14M, AppColors.grey600),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(CompatibilityStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
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

  Color _getStatusColor(CompatibilityStatus status) {
    return switch (status) {
      CompatibilityStatus.completed => const Color(0xFFFF1493),
      CompatibilityStatus.pending => AppColors.grey500,
      CompatibilityStatus.error => AppColors.point900,
      CompatibilityStatus.input => AppColors.grey500,
    };
  }

  String _getStatusText(CompatibilityStatus status) {
    return switch (status) {
      CompatibilityStatus.completed => '완료',
      CompatibilityStatus.pending => '분석중',
      CompatibilityStatus.error => '오류',
      CompatibilityStatus.input => '입력중',
    };
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFFE91E63); // 핑크
    if (score >= 80) return const Color(0xFFFF1744); // 레드
    if (score >= 70) return const Color(0xFFFF4081); // 마젠타
    return AppColors.grey500;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return '최고의 궁합이에요! ✨';
    if (score >= 80) return '아주 좋은 궁합이에요! 💫';
    if (score >= 70) return '좋은 궁합이에요! 🌟';
    return '잘 맞는 부분을 찾아보세요 😊';
  }
}
