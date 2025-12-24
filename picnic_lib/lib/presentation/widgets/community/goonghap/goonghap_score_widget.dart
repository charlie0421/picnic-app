import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class GoonghapScoreWidget extends StatelessWidget {
  const GoonghapScoreWidget({
    super.key,
    required this.goonghap,
  });

  final GoonghapModel? goonghap;

  /// 현재 언어에 해당하는 LocalizedGoonghap을 찾고, 없으면 fallback 언어로 시도
  LocalizedGoonghap? _getLocalizedResultWithFallback(String currentLocale) {
    final results = goonghap?.localizedResults;
    if (results == null) return null;

    // 1. 현재 언어 시도
    if (results.containsKey(currentLocale)) {
      return results[currentLocale];
    }

    // 2. Fallback 순서: en -> ko -> 첫 번째 사용 가능한 언어
    const fallbackOrder = ['en', 'ko'];
    for (final fallback in fallbackOrder) {
      if (results.containsKey(fallback)) {
        return results[fallback];
      }
    }

    // 3. 아무 언어라도 있으면 반환
    if (results.isNotEmpty) {
      return results.values.first;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final currentLocale = Localizations.localeOf(context).languageCode;
        final localizedResult = _getLocalizedResultWithFallback(currentLocale);

        // 결과가 있는 경우 (결제 완료 또는 미결제 모두)
        if (localizedResult != null) {
          return goonghap?.isPaid ?? false
              ? AnimatedGoonghapBar(
                  score: localizedResult.score,
                  message: localizedResult.scoreTitle,
                )
              : ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary500,
                          AppColors.primary500,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)
                          .goonghap_purchase_message(
                              getLocaleTextFromJson(
                                  goonghap?.artist.name ?? {}, context)),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                    ),
                  ),
                );
        }

        // localizedResults가 없지만 goonghap 데이터가 있는 경우 - 미결제 UI 표시
        if (goonghap != null) {
          return ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary500,
                    AppColors.primary500,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).goonghap_purchase_message(
                    getLocaleTextFromJson(
                        goonghap?.artist.name ?? {}, context)),
                style: getTextStyle(AppTypo.body14B, AppColors.grey00),
              ),
            ),
          );
        }

        return const SizedBox.shrink(); // goonghap 자체가 null인 경우에만 빈 위젯 반환
      },
    );
  }
}

class AnimatedGoonghapBar extends StatelessWidget {
  final int score;
  final String message;

  const AnimatedGoonghapBar({
    super.key,
    required this.score,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Stack(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    final actualWidth = constraints.maxWidth * value;
                    return ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: actualWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary500,
                                AppColors.primary500,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$score%',
                        style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
