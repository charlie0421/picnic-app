import 'package:flutter/material.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';

class CompatibilityResultView extends StatelessWidget {
  const CompatibilityResultView({
    super.key,
    required this.compatibility,
    this.language = 'ko', // 기본 언어를 한국어로 설정
  });

  final CompatibilityModel compatibility;
  final String language;

  @override
  Widget build(BuildContext context) {
    final localizedResult = compatibility.getLocalizedResult(language);

    if (localizedResult == null) {
      return Container(
          margin: const EdgeInsets.only(top: 24),
          child: ErrorView(context,
              error: "localizedResult == null",
              stackTrace: StackTrace.current));
    }

    // 로컬라이즈된 결과가 없으면 기본 결과 사용
    final score = compatibility.compatibilityScore ?? 0;
    final summary = localizedResult.compatibilitySummary ?? '';
    final details = localizedResult.details;
    final tips = localizedResult.tips;

    return SingleChildScrollView(
      child: Column(
        children: [
          // 궁합 점수
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Text(
                summary,
                textAlign: TextAlign.center,
                style: getTextStyle(AppTypo.body16M, AppColors.grey900),
              ),
            ),
          ),

          // 스타일 분석
          if (details?.style != null) ...[
            _buildSection(
              title: _getLocalizedTitle(
                  '스타일 분석', 'Style Analysis', 'スタイル分析', '风格分析'),
              icon: Icons.style,
              child: Column(
                children: [
                  _buildDetailItem(
                    _getLocalizedArtistName(compatibility.artist, language),
                    details?.style.idolStyle ?? '',
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    _getLocalizedText(
                        '당신의 스타일', 'Your Style', 'あなたのスタイル', '你的风格'),
                    details?.style.userStyle ?? '',
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    _getLocalizedText('커플 스타일 제안', 'Couple Style Suggestion',
                        'カップルスタイル提案', '情侣风格建议'),
                    details?.style.coupleStyle ?? '',
                  ),
                ],
              ),
            ),
          ],

          // 추천 활동
          if (details?.activities != null) ...[
            _buildSection(
              title: _getLocalizedText(
                  '추천 활동', 'Recommended Activities', 'おすすめの活動', '推荐活动'),
              icon: Icons.local_activity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...?details?.activities.recommended.map(
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
                  if (details!.activities.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      details.activities.description,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 궁합 높이기 팁
          if (tips.isNotEmpty)
            _buildSection(
              title: _getLocalizedText('궁합 높이기 팁',
                  'Tips to Improve Compatibility', '相性を高めるヒント', '提高相配度的建议'),
              icon: Icons.tips_and_updates,
              child: Column(
                children: tips
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

  String _getLocalizedText(String ko, String en, String ja, String zh) {
    switch (language) {
      case 'ko':
        return ko;
      case 'en':
        return en;
      case 'ja':
        return ja;
      case 'zh':
        return zh;
      default:
        return ko;
    }
  }

  String _getLocalizedTitle(String ko, String en, String ja, String zh) {
    return _getLocalizedText(ko, en, ja, zh);
  }

  String _getLocalizedArtistName(ArtistModel artist, String language) {
    final name = artist.name[language] ?? artist.name['ko'] ?? '';
    return _getLocalizedText(
        '${name}님의 스타일', "${name}'s Style", '${name}さんのスタイル', '${name}的风格');
  }
}
