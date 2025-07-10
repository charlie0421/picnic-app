import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityScoreWidget extends StatelessWidget {
  const CompatibilityScoreWidget({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel? compatibility;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final currentLocale = getLocaleLanguage();
        final localizedResult = compatibility?.localizedResults?[currentLocale];
        if (localizedResult != null) {
          return compatibility?.isPaid ?? false
              ? AnimatedCompatibilityBar(
                  score: localizedResult.score,
                  message: localizedResult.scoreTitle,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
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
                            .compatibility_purchase_message(
                                getLocaleTextFromJson(
                                    compatibility?.artist.name ?? {})),
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

class AnimatedCompatibilityBar extends StatefulWidget {
  final int score;
  final String message;

  const AnimatedCompatibilityBar({
    super.key,
    required this.score,
    required this.message,
  });

  @override
  State<AnimatedCompatibilityBar> createState() =>
      AnimatedCompatibilityBarState();
}

class AnimatedCompatibilityBarState extends State<AnimatedCompatibilityBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _widthAnimation,
                builder: (context, child) {
                  final actualWidth =
                      constraints.maxWidth * _widthAnimation.value;

                  return ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
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
                  '${widget.score}%',
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                ),
                SizedBox(width: 8),
                Text(
                  widget.message,
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
