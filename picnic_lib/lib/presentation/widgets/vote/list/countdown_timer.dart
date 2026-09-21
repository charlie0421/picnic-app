import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoteStatus status;
  final VoidCallback? onRefresh;

  const CountdownTimer({
    super.key,
    required this.endTime,
    required this.status,
    this.onRefresh,
  });

  /// 남은시간 숫자 타일 한 변.
  ///
  /// 이 안의 글자는 [AppTypo.caption12M] — `getTextStyle` 은 폰트 크기를
  /// ScreenUtil 로 환산하지 않으므로 기기와 무관하게 12px 이다. 담는 그릇도
  /// 같은 이유로 고정 크기를 유지한다(글자는 그대로인데 타일만 줄면 글자가
  /// 타일 밖으로 삐져나온다).
  static const double digitSize = 18;

  /// 숫자 타일 좌우 마진. 같은 단위의 두 자리는 `2 * digitGap` 만큼 벌어진다.
  static const double digitGap = 1;

  /// 단위 구분자(`D`, `:`) 좌우 여백.
  ///
  /// 예전에는 구분자 문자열이 `' : '` 처럼 **공백으로** 여백을 냈다. 공백 폭은
  /// 폰트와 텍스트 배율에 따라 달라져서(같은 12px 에서도 Pretendard 5.1px,
  /// 테스트 폰트 13.5px) 이 행의 폭 수요를 예측할 수 없게 만들고, 배율을 올리면
  /// 여백까지 같이 커졌다. 여백은 레이아웃으로 내고 문자열에는 글자만 둔다.
  static const double separatorGap = 4;

  /// 왼쪽에서 [index] 번째 숫자 타일에 붙는 키.
  ///
  /// 카드가 좁아졌을 때 "타일이 몇 개 그려졌고 화면에서 몇 픽셀인가" 를 테스트가
  /// 직접 잴 수 있어야, 오버플로를 [FittedBox]/스크롤뷰/타일 축소로 숨기는
  /// 우회를 회귀로 잡을 수 있다.
  @visibleForTesting
  static Key digitKey(int index) => ValueKey('countdown_timer.digit.$index');

  /// Space the "upcoming" label keeps under itself, above the digits.
  static const double upcomingLabelGap = 16;

  /// The "upcoming" label's box never gets shorter than this.
  static const double upcomingLabelMinHeight = 20;

  static TextStyle get digitStyle =>
      getTextStyle(AppTypo.caption12M, AppColors.grey900);

  static TextStyle upcomingStyle(Color color) =>
      getTextStyle(AppTypo.caption12B, color);

  static TextStyle get endStyle => getTextStyle(
    AppTypo.body14B,
    AppColors.primary500,
  ).copyWith(decoration: TextDecoration.underline);

  /// Height of [text] as a `Text` with [style] would lay it out here.
  ///
  /// `Text` paints its style on top of the ambient [DefaultTextStyle], which
  /// can bring its own line height; measuring [style] alone came out 5px
  /// short at 2.0x. So the ambient style, text scaler and height behaviour are
  /// all taken from [context], exactly as the widget will get them.
  static double _textHeight(
    BuildContext context,
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) {
    final ambient = DefaultTextStyle.of(context);
    final painter = TextPainter(
      text: TextSpan(text: text, style: ambient.style.merge(style)),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: ambient.textHeightBehavior,
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// The digit tile's height: the design's 18, or the digit's own line when
  /// the user's text scale makes that taller.
  ///
  /// The tile used to be a fixed 18x18. The digit paints inside a paragraph
  /// that clips itself to the height it gets, so from 1.2x its line was cut,
  /// and from about 1.5x the glyphs lost their bottom — at 2.0x nearly half of
  /// every digit was gone. The app does not clamp text scaling.
  ///
  /// Only the height follows the text. The width stays [digitSize]: one digit
  /// is narrower than that even at 2.6x, and the row's width is the budget
  /// the 320dp home card is tested against.
  static double digitTileHeight(BuildContext context) =>
      math.max(digitSize, _textHeight(context, '0', digitStyle).ceilToDouble());

  /// The height this widget lays out at for [status] in [maxWidth].
  ///
  /// Callers that budget a card before layout must use this rather than
  /// [digitSize]: the build below reads the very same numbers, so what is
  /// budgeted is what is drawn.
  static double preferredHeight(
    BuildContext context, {
    required VoteStatus status,
    required double maxWidth,
  }) {
    final l10n = AppLocalizations.of(context);
    if (status == VoteStatus.end) {
      return _textHeight(
        context,
        l10n.label_vote_end,
        endStyle,
        maxWidth: maxWidth,
      );
    }
    final digits = digitTileHeight(context);
    if (status != VoteStatus.upcoming) return digits;
    final label = _textHeight(
      context,
      l10n.label_vote_upcoming,
      upcomingStyle(AppColors.secondary500),
      maxWidth: maxWidth,
    );
    return math.max(upcomingLabelMinHeight, label) + upcomingLabelGap + digits;
  }

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  Color _color = AppColors.secondary500;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = widget.endTime.difference(DateTime.now().toUtc());
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
    }
    _updateColor();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = widget.endTime.difference(DateTime.now().toUtc());
          if (_timeLeft.isNegative) {
            _timeLeft = Duration.zero;
            _timer?.cancel();
            // 타이머가 끝나는 즉시 새로고침 트리거 (프레임 종료 후 안전 호출)
            if (widget.onRefresh != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onRefresh!.call();
              });
            }
          }
          _updateColor();
        });
      }
    });
  }

  void _updateColor() {
    if (_timeLeft.inHours > 24) {
      _color = AppColors.secondary500;
    } else if (_timeLeft.inHours > 1) {
      _color = AppColors.sub500;
    } else if (_timeLeft.inMinutes > 0) {
      _color = AppColors.point500;
    } else {
      _color = AppColors.grey300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    // 타일 키는 행 전체에서 왼쪽부터 이어진다 — 일(日)이 세 자리가 되어도
    // 번호가 밀리지 않게 한 카운터로 센다.
    var digitIndex = 0;
    final tileHeight = CountdownTimer.digitTileHeight(context);
    List<Widget> unit(int value, [String? label]) {
      final digits = value.toString().padLeft(2, '0');
      return <Widget>[
        for (var i = 0; i < digits.length; i++)
          _buildTimeCircle(digits[i], digitIndex++, tileHeight),
        if (label != null) _buildSeparator(label),
      ];
    }

    return Column(
      children: [
        if (widget.status == VoteStatus.upcoming)
          Container(
            // A minimum, not a fixed height: at 1.3x and above the label is
            // taller than 20 and a fixed box clipped it in every language.
            constraints: const BoxConstraints(
              minHeight: CountdownTimer.upcomingLabelMinHeight,
            ),
            margin: const EdgeInsets.only(
              bottom: CountdownTimer.upcomingLabelGap,
            ),
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context).label_vote_upcoming,
              style: CountdownTimer.upcomingStyle(_color),
            ),
          ),
        if (widget.status == VoteStatus.end)
          Text(
            AppLocalizations.of(context).label_vote_end,
            style: CountdownTimer.endStyle,
          ),
        if (widget.status != VoteStatus.end)
          SizedBox(
            height: tileHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ...unit(totalDays, 'D'),
                ...unit(hours),
                _buildSeparator(':'),
                ...unit(minutes),
                _buildSeparator(':'),
                ...unit(seconds),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeparator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CountdownTimer.separatorGap,
      ),
      child: Text(
        text,
        style: getTextStyle(AppTypo.caption12M, AppColors.grey900),
      ),
    );
  }

  Widget _buildTimeCircle(String time, int index, double height) {
    return Container(
      key: CountdownTimer.digitKey(index),
      width: CountdownTimer.digitSize,
      height: height,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: CountdownTimer.digitGap),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(time, style: CountdownTimer.digitStyle),
    );
  }
}
