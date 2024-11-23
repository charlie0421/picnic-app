import 'package:flutter/material.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityResultView extends StatelessWidget {
  const CompatibilityResultView({
    super.key,
    required this.compatibility,
    this.language = 'ko',
  });

  final CompatibilityModel compatibility;
  final String language;

  @override
  Widget build(BuildContext context) {
    // 한국어 데이터 처리 - 기본 데이터를 우선 사용
    final LocalizedCompatibility currentResult = language == 'ko'
        ? LocalizedCompatibility(
            language: 'ko',
            compatibilitySummary: compatibility.compatibilitySummary ?? '',
            details: compatibility.details,
            tips: compatibility.tips ?? [],
          )
        : compatibility.getLocalizedResult(language) ??
            LocalizedCompatibility(
              language: language,
              compatibilitySummary: compatibility.compatibilitySummary ?? '',
              details: compatibility.details,
              tips: compatibility.tips ?? [],
            );

    return SingleChildScrollView(
      child: Column(
        children: [
          if (currentResult.compatibilitySummary.isNotEmpty)
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(
                  currentResult.compatibilitySummary,
                  textAlign: TextAlign.center,
                  style: getTextStyle(AppTypo.body16M, AppColors.grey900),
                ),
              ),
            ),

          // 스타일 분석
          if (currentResult.details?.style != null) ...[
            _buildSection(
              title: '스타일 분석',
              icon: Icons.style,
              child: Column(
                children: [
                  _buildDetailItem(
                    _getLocalizedArtistName(compatibility.artist),
                    currentResult.details!.style.idolStyle,
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '당신의 스타일',
                    currentResult.details!.style.userStyle,
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '커플 스타일 제안',
                    currentResult.details!.style.coupleStyle,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 추천 활동
          if (currentResult.details?.activities != null) ...[
            _buildSection(
              title: '추천 활동',
              icon: Icons.local_activity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...currentResult.details!.activities.recommended.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
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
                  if (currentResult
                      .details!.activities.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      currentResult.details!.activities.description,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 궁합 높이기 팁
          if (currentResult.tips?.isNotEmpty ?? false) ...[
            _buildSection(
              title: '궁합 높이기 팁',
              icon: Icons.tips_and_updates,
              child: Column(
                children: currentResult.tips!
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
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
          ],
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

  String _getLocalizedArtistName(ArtistModel artist) {
    final name = artist.name['ko'] ?? '';
    return '${name}님의 스타일';
  }
}
