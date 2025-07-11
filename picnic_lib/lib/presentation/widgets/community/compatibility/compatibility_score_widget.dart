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
        final currentLocale = Localizations.localeOf(context).languageCode;
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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _widthAnimation = Tween<double>(
        begin: 0,
        end: (widget.score / 100).clamp(0.0, 1.0), // 안전한 범위 제한
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      // 위젯이 마운트된 후 애니메이션 시작하여 렌더링 안정성 확보
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          try {
            _controller.forward();
          } catch (e) {
            // 애니메이션 시작 실패 시 무시
            if (mounted) {
              setState(() {
                // 애니메이션 없이 최종 상태로 설정
              });
            }
          }
        }
      });
    } catch (e) {
      // AnimationController 초기화 실패 시 더미 컨트롤러 생성
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
      _widthAnimation =
          AlwaysStoppedAnimation((widget.score / 100).clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _controller.dispose();
    } catch (e) {
      // dispose 실패 시 무시
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      // Semantics 정보 추가하여 일관성 보장
      child: Semantics(
        label: '궁합 점수 ${widget.score}%, ${widget.message}',
        value: '${widget.score}%',
        child: Stack(
          children: [
            // AnimatedBuilder를 try-catch로 감싸서 안전하게 처리
            Builder(
              builder: (context) {
                try {
                  return AnimatedBuilder(
                    animation: _widthAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            // constraints 계산 대신 FractionallySizedBox 사용
                            widthFactor: _widthAnimation.value.clamp(0.0, 1.0),
                            child: Container(
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
                        ),
                      );
                    },
                  );
                } catch (e) {
                  // 애니메이션 실패 시 정적 바 표시
                  return ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (widget.score / 100).clamp(0.0, 1.0),
                        child: Container(
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
                    ),
                  );
                }
              },
            ),
            // 텍스트 위젯을 별도 RepaintBoundary로 분리하여 렌더링 최적화
            RepaintBoundary(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.score}%',
                      style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
