import 'package:flutter/material.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityResultView extends StatelessWidget {
  const CompatibilityResultView({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 궁합 점수
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${compatibility.compatibilityScore}%',
                    style: getTextStyle(
                      AppTypo.title18B,
                      _getScoreColor(compatibility.compatibilityScore ?? 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    compatibility.compatibilitySummary ?? '',
                    textAlign: TextAlign.center,
                    style: getTextStyle(AppTypo.body16M, AppColors.grey900),
                  ),
                ],
              ),
            ),
          ),

          // 스타일 분석
          if (compatibility.details?.style != null) ...[
            _buildSection(
              title: '스타일 분석',
              icon: Icons.style,
              child: Column(
                children: [
                  _buildDetailItem(
                    '${compatibility.artist.name['ko']}님의 스타일',
                    compatibility.details?.style?.idol_style ?? '',
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '당신의 스타일',
                    compatibility.details?.style?.user_style ?? '',
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '커플 스타일 제안',
                    compatibility.details?.style?.couple_style ?? '',
                  ),
                ],
              ),
            ),
          ],

          // 추천 활동
          if (compatibility.details?.activities != null &&
              compatibility.details?.activities != null) ...[
            _buildSection(
              title: '추천 활동',
              icon: Icons.local_activity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...compatibility.details!.activities!.recommended!.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppColors.primary500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity,
                              style: getTextStyle(
                                  AppTypo.body14M, AppColors.grey900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (compatibility
                      .details!.activities!.description!.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      compatibility.details!.activities!.description ?? '',
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 궁합 높이기 팁
          if (compatibility.tips != null && compatibility.tips!.isNotEmpty)
            _buildSection(
              title: '궁합 높이기 팁',
              icon: Icons.tips_and_updates,
              child: Column(
                children: compatibility.tips!
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: AppColors.primary500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: getTextStyle(
                                    AppTypo.body14M, AppColors.grey900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary500),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: getTextStyle(AppTypo.body14B, AppColors.grey900),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: getTextStyle(AppTypo.body14M, AppColors.grey900),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.primary500;
    if (score >= 80) return const Color(0xFFFF9500);
    if (score >= 70) return const Color(0xFF34C759);
    return AppColors.grey600;
  }
}
