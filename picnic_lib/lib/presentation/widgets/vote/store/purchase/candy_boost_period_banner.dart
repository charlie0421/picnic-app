import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview_view.dart';
import 'package:picnic_lib/ui/style.dart';

class CandyBoostPeriodBanner extends StatefulWidget {
  const CandyBoostPeriodBanner({
    super.key,
    required this.startsAt,
    required this.endsAt,
    required this.bonusPercent,
  });

  /// The bounded, currently-active occurrence to display — never the full
  /// recurring campaign envelope. Callers are responsible for resolving
  /// this (see `resolveActiveBoostOccurrence`) before reaching this widget.
  final DateTime startsAt;
  final DateTime endsAt;
  final int bonusPercent;

  @override
  State<CandyBoostPeriodBanner> createState() => _CandyBoostPeriodBannerState();
}

class _CandyBoostPeriodBannerState extends State<CandyBoostPeriodBanner>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      return;
    }
    _entrance.forward().then((_) {
      if (mounted) _pulse.repeat(count: 2);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = widget.startsAt.toUtc().add(const Duration(hours: 9));
    final endRaw = widget.endsAt.toUtc().add(const Duration(hours: 9));
    // A midnight end is exclusive (the boundary itself is not "active"), so
    // the last day actually covered is the day before — display that day
    // inclusively rather than showing a date the occurrence never reaches.
    final endIsMidnight =
        endRaw.hour == 0 &&
        endRaw.minute == 0 &&
        endRaw.second == 0 &&
        endRaw.millisecond == 0;
    final end = endIsMidnight
        ? endRaw.subtract(const Duration(days: 1))
        : endRaw;
    // All-day only when the boundary is a plain midnight-to-midnight range
    // with no partial-day clip on either side — a partial start or end
    // always carries a meaningful clock time, so it (and its counterpart,
    // for a legible single range) keeps showing time.
    final isAllDay =
        start.hour == 0 &&
        start.minute == 0 &&
        start.second == 0 &&
        start.millisecond == 0 &&
        endIsMidnight;
    final crossesYear = start.year != end.year;

    String formatSide(DateTime value, {required bool includeYear}) {
      final date = includeYear
          ? DateFormat.yMd(locale).format(value)
          : DateFormat.Md(locale).format(value);
      final weekday = DateFormat.E(locale).format(value);
      if (isAllDay) return '$date ($weekday)';
      final time = DateFormat.Hm(locale).format(value);
      return '$date ($weekday) $time';
    }

    final startText = formatSide(start, includeYear: true);
    final endText = formatSide(end, includeYear: crossesYear);
    final periodText = '$startText – $endText KST';

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: AppColors.point900),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).candy_boost_day,
                        style: getTextStyle(
                          AppTypo.caption12B,
                          AppColors.grey900,
                        ),
                      ),
                    ),
                    ScaleTransition(
                      scale: TweenSequence<double>([
                        TweenSequenceItem(
                          tween: Tween(begin: 1, end: 1.16),
                          weight: 20,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 1.16, end: 1),
                          weight: 20,
                        ),
                        TweenSequenceItem(tween: ConstantTween(1), weight: 60),
                      ]).animate(_pulse),
                      child: Image.asset(
                        kBonusStarCandyAsset,
                        key: Key(
                          reduceMotion
                              ? 'candy-boost-banner-static-bonus-icon'
                              : 'candy-boost-banner-bonus-icon',
                        ),
                        package: 'picnic_lib',
                        width: 15,
                        height: 15,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${widget.bonusPercent}%',
                      style: getTextStyle(
                        AppTypo.caption12B,
                        AppColors.point900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    periodText,
                    maxLines: 1,
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return FadeTransition(
      key: const Key('candy-boost-period-banner'),
      opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final glow = 1 - ((_entrance.value * 2) - 1).abs();
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.point500.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.point500.withValues(alpha: .2 + (glow * .3)),
              ),
              boxShadow: reduceMotion
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.point500.withValues(alpha: glow * .18),
                        blurRadius: 12 * glow,
                        spreadRadius: glow,
                      ),
                    ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              content,
              if (!reduceMotion)
                Positioned.fill(
                  key: const Key('candy-boost-banner-shine'),
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _entrance,
                      builder: (context, child) => FractionalTranslation(
                        translation: Offset(-1.4 + (_entrance.value * 2.8), 0),
                        child: Transform.rotate(
                          angle: -.25,
                          child: Align(
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: .72),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
