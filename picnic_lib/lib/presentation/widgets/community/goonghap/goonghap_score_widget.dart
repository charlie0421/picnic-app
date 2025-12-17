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

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final currentLocale = Localizations.localeOf(context).languageCode;
        final localizedResult = goonghap?.localizedResults?[currentLocale];
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
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary500,
                          AppColors.primary500,
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)
                            .goonghap_purchase_message(
                                getLocaleTextFromJson(
                                    goonghap?.artist.name ?? {}, context)),
                        style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                      ),
                    ),
                  ),
                );
        }
        return const SizedBox.shrink(); // 결과가 없을 경우 빈 위젯 반환
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
    return Container(
      height: 48,
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final actualWidth = constraints.maxWidth * value;
                  return ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: actualWidth,
                        height: 48,
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
              );
            },
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '$score%',
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
