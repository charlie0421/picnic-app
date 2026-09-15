import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/picnic_ui_test_environment.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

const _measurementViewport = Size(851, 393);
const _locales = <String>['ko', 'en', 'th', 'my', 'ja', 'zh', 'id'];
const _textScales = <double>[1.0, 1.3, 2.0];
const _columnGaps = <double>[16, 24, 32];

// PICNIC-2695 (0819c3a92) replaces the hidden 24 strip with a 48 top-close
// strip only when it fits, so visible-close content has exactly 24 less height.
// This branch intentionally stays on c83a3ee1d; the constant keeps both
// post-2695 budgets measurable without editing or importing its files.
const _topCloseExtraChromeHeight = 24.0;

// A finite fixture is necessary because the general wallet is a BigInt and
// therefore has no finite all-values width. Eight visible digits are enough
// to expose the trade-off without pretending to impose a new product limit.
const _editableAmount = '9,999,999';
const _balanceAmount = '9,999,999';
const _jmaVoteHint = '9,999개의 투표를 진행합니다.';
const _jmaCalculation = 'JMA 9,999투표 = 보너스 5개 + 별사탕 299,820개';

const _shortArtistNames = <String, String>{
  'ko': '지민',
  'en': 'Jimin',
  'th': 'จีมิน',
  'my': 'ဂျီမင်',
  'ja': 'ジミン',
  'zh': '智旻',
  'id': 'Jimin',
};

const _shortGroupNames = <String, String>{
  'ko': '방탄소년단',
  'en': 'BTS',
  'th': 'บีทีเอส',
  'my': 'ဘီတီအက်စ်',
  'ja': '防弾少年団',
  'zh': '防弹少年团',
  'id': 'BTS',
};

const _longArtistNames = <String, String>{
  'ko': '아주긴아티스트이름아주긴아티스트이름',
  'en': 'The Internationally Acclaimed Artist Name',
  'th': 'ชื่อศิลปินนานาชาติที่ยาวมากเป็นพิเศษ',
  'my': 'အလွန်ရှည်လျားသောနိုင်ငံတကာအနုပညာရှင်အမည်',
  'ja': 'とても長い国際的なアーティストの名前',
  'zh': '非常非常长的国际艺术家姓名示例',
  'id': 'Nama Artis Internasional yang Sangat Panjang',
};

const _longGroupNames = <String, String>{
  'ko': '아주긴그룹이름아주긴그룹이름아주긴그룹이름',
  'en': 'The Extraordinarily Long International Group Name',
  'th': 'ชื่อกลุ่มนานาชาติที่ยาวมากเป็นพิเศษ',
  'my': 'အလွန်ရှည်လျားသောနိုင်ငံတကာအဖွဲ့အမည်',
  'ja': '非常に長い国際的なグループの名前',
  'zh': '非常非常长的国际组合名称示例',
  'id': 'Nama Grup Internasional yang Sangat Panjang',
};

enum _HorizontalGeometry {
  // Existing controls inherit `.w` from the full 851-wide ScreenUtil root.
  inherited,

  // PICNIC-2697 candidate: horizontal control tokens stay local logical px.
  local,
}

double _horizontal(double value, _HorizontalGeometry geometry) =>
    geometry == _HorizontalGeometry.inherited
    ? PicnicUi.horizontal(value)
    : value;

double _round(double value) => (value * 100).roundToDouble() / 100;

TextPainter _painter(
  BuildContext context,
  String text,
  TextStyle style, {
  int? maxLines,
}) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: Directionality.of(context),
  textScaler: MediaQuery.textScalerOf(context),
  locale: Localizations.maybeLocaleOf(context),
  maxLines: maxLines,
);

double _naturalTextWidth(BuildContext context, String text, TextStyle style) {
  final painter = _painter(context, text, style)..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

double _minimumTextWidthForLines(
  BuildContext context,
  String text,
  TextStyle style, {
  required int maxLines,
}) {
  if (text.isEmpty) return 0;
  final natural = _naturalTextWidth(context, text, style);
  if (maxLines == 1) return natural;

  bool fits(double width) {
    final painter = _painter(context, text, style, maxLines: maxLines)
      ..layout(maxWidth: width);
    final result =
        !painter.didExceedMaxLines &&
        painter.computeLineMetrics().length <= maxLines;
    painter.dispose();
    return result;
  }

  var low = 0.0;
  var high = natural;
  for (var iteration = 0; iteration < 48; iteration += 1) {
    final middle = (low + high) / 2;
    if (fits(middle)) {
      high = middle;
    } else {
      low = middle;
    }
  }
  return high;
}

double _textHeight(
  BuildContext context,
  String text,
  TextStyle style, {
  required double maxWidth,
}) => measureVotingTextHeight(context, text, style, maxWidth: maxWidth);

final class _RightMeasurement {
  const _RightMeasurement({
    required this.general,
    required this.generalNoHint,
    required this.jma,
    required this.combined,
    required this.controlling,
    required this.parts,
  });

  final double general;
  final double generalNoHint;
  final double jma;
  final double combined;
  final String controlling;
  final Map<String, double> parts;

  Map<String, Object> toJson() => <String, Object>{
    'general': _round(general),
    'generalNoHint': _round(generalNoHint),
    'jma': _round(jma),
    'combined': _round(combined),
    'controlling': controlling,
    'parts': parts.map((key, value) => MapEntry(key, _round(value))),
  };
}

_RightMeasurement _measureRight(
  BuildContext context,
  AppLocalizations l10n, {
  required int maxLines,
  required _HorizontalGeometry geometry,
}) {
  double h(double value) => _horizontal(value, geometry);
  final useAllStyle = PicnicUi.text(size: 14, weight: FontWeight.w500);
  final inputStyle = PicnicUi.text(size: 16, weight: FontWeight.w700);
  final generalButtonStyle = PicnicUi.text(size: 18, weight: FontWeight.w600);
  final jmaButtonStyle = PicnicUi.text(size: 18, weight: FontWeight.w700);
  final hintStyle = PicnicUi.text(size: 12, weight: FontWeight.w600);

  final generalCheck =
      h(20) +
      h(4) +
      _minimumTextWidthForLines(
        context,
        l10n.label_checkbox_entire_use,
        useAllStyle,
        maxLines: maxLines,
      );
  final jmaCheck =
      20 +
      h(4) +
      _minimumTextWidthForLines(
        context,
        l10n.jma_voting_use_all,
        useAllStyle,
        maxLines: maxLines,
      );

  final editableWidth = _naturalTextWidth(context, _editableAmount, inputStyle);
  final hintWidth = _naturalTextWidth(
    context,
    l10n.label_input_input,
    PicnicUi.text(size: 16, color: PicnicUi.quietText),
  );
  final generalInput =
      2 +
      h(4) +
      PicnicUi.minimumTapTarget +
      h(24) * 2 +
      math.max(editableWidth, hintWidth);
  // PICNIC-2697: the hint is a placeholder ("입력"); at a large scale in a long
  // locale it, not the digits, decides the field's minimum width. Measure the
  // digits-only variant too, so the design can tell an accidental constraint
  // from a real one.
  final generalInputNoHint =
      2 + h(4) + PicnicUi.minimumTapTarget + h(24) * 2 + editableWidth;
  final jmaInput =
      4 + h(4) + PicnicUi.minimumTapTarget + h(24) * 2 + editableWidth;

  final generalButton =
      h(12) * 2 +
      _minimumTextWidthForLines(
        context,
        l10n.label_button_vote,
        generalButtonStyle,
        maxLines: maxLines,
      );
  final jmaActiveButton =
      h(12) * 2 +
      20 +
      h(8) +
      _minimumTextWidthForLines(
        context,
        l10n.label_button_vote,
        jmaButtonStyle,
        maxLines: maxLines,
      );
  final jmaHint =
      h(24) +
      _minimumTextWidthForLines(
        context,
        _jmaVoteHint,
        hintStyle,
        maxLines: maxLines,
      );

  final parts = <String, double>{
    'generalCheck': generalCheck,
    'jmaCheck': jmaCheck,
    'generalInput': generalInput,
    'generalInputNoHint': generalInputNoHint,
    'jmaInput': jmaInput,
    'generalButton': generalButton,
    'jmaActiveButton': jmaActiveButton,
    'jmaHint': jmaHint,
  };
  final general = math.max(generalCheck, math.max(generalInput, generalButton));
  final generalNoHint = math.max(
    generalCheck,
    math.max(generalInputNoHint, generalButton),
  );
  final jma = <double>[
    jmaCheck,
    jmaInput,
    jmaActiveButton,
    jmaHint,
  ].reduce(math.max);
  final combined = math.max(general, jma);
  final controlling = parts.entries
      .reduce((left, right) => left.value >= right.value ? left : right)
      .key;
  return _RightMeasurement(
    generalNoHint: generalNoHint,
    general: general,
    jma: jma,
    combined: combined,
    controlling: controlling,
    parts: parts,
  );
}

final class _LeftMeasurement {
  const _LeftMeasurement({
    required this.generalFloor,
    required this.generalPreferred,
    required this.jmaFloor,
    required this.jmaPreferred,
    required this.combinedFloor,
    required this.combinedPreferred,
    required this.controlling,
    required this.parts,
  });

  final double generalFloor;
  final double generalPreferred;
  final double jmaFloor;
  final double jmaPreferred;
  final double combinedFloor;
  final double combinedPreferred;
  final String controlling;
  final Map<String, double> parts;

  Map<String, Object> toJson() => <String, Object>{
    'generalFloor': _round(generalFloor),
    'generalPreferred': _round(generalPreferred),
    'jmaFloor': _round(jmaFloor),
    'jmaPreferred': _round(jmaPreferred),
    'combinedFloor': _round(combinedFloor),
    'combinedPreferred': _round(combinedPreferred),
    'controlling': controlling,
    'parts': parts.map((key, value) => MapEntry(key, _round(value))),
  };
}

_LeftMeasurement _measureLeft(
  BuildContext context,
  AppLocalizations l10n, {
  required String locale,
  required bool longNames,
  required int maxLines,
  required _HorizontalGeometry geometry,
}) {
  double h(double value) => _horizontal(value, geometry);
  final artist = longNames
      ? _longArtistNames[locale]!
      : _shortArtistNames[locale]!;
  final group = longNames
      ? _longGroupNames[locale]!
      : _shortGroupNames[locale]!;

  final artistWidth = _minimumTextWidthForLines(
    context,
    artist,
    PicnicUi.text(size: 16, weight: FontWeight.w700),
    maxLines: maxLines,
  );
  final groupWidth = _minimumTextWidthForLines(
    context,
    group,
    PicnicUi.text(size: 12, color: PicnicUi.secondaryText),
    maxLines: maxLines,
  );
  final stackedNameWidth = math.max(artistWidth, groupWidth);

  // The proposed two-column identity puts the portrait beside the two-name
  // stack. The floor uses the PICNIC-2694 32px portrait; preferred uses each
  // dialog's capped 80/60px portrait.
  final generalIdentityFloor =
      kVoteDialogMinimumPortrait + 12 + stackedNameWidth;
  final generalIdentityPreferred =
      VotingArtistImage.preferredHeight() + 12 + stackedNameWidth;
  const jmaPreferredPortrait = 60.0;
  final jmaIdentityFloor = kVoteDialogMinimumPortrait + 12 + stackedNameWidth;
  final jmaIdentityPreferred =
      voteDialogDecorationExtent(jmaPreferredPortrait) + 12 + stackedNameWidth;

  final balanceStyle = PicnicUi.text(size: 16, weight: FontWeight.w700);
  final rechargeStyle = PicnicUi.text(size: 14, weight: FontWeight.w700);
  final balanceTextWidth = _naturalTextWidth(
    context,
    _balanceAmount,
    balanceStyle,
  );
  final recharge = math.max(
    PicnicUi.minimumTapTarget,
    h(12) * 2 +
        _minimumTextWidthForLines(
          context,
          l10n.label_button_recharge,
          rechargeStyle,
          maxLines: maxLines,
        ) +
        h(4) +
        h(16),
  );
  final generalBalance = h(32) + h(4) + balanceTextWidth + recharge;

  final badge =
      h(16) * 2 +
      20 +
      h(8) +
      _minimumTextWidthForLines(
        context,
        'Jupiter Music Awards',
        PicnicUi.text(size: 12, weight: FontWeight.w700),
        maxLines: maxLines,
      );

  final panelStyle = PicnicUi.text(size: 12, weight: FontWeight.w700);
  final regularHolding =
      40 + h(4) + _naturalTextWidth(context, '3,000', panelStyle);
  final bonusHolding =
      18 + h(4) + _naturalTextWidth(context, '50개', panelStyle);
  final holdings = maxLines == 1
      ? regularHolding + h(8) + bonusHolding
      : math.max(regularHolding, bonusHolding);
  final usableRegular =
      h(8) + 22 + h(12) + _naturalTextWidth(context, '100', panelStyle);
  final usableBonus = 18 + h(4) + _naturalTextWidth(context, '5개', panelStyle);
  final jmaBalancePanel =
      h(8) * 2 +
      <double>[
        _minimumTextWidthForLines(
          context,
          l10n.jma_voting_my_star_candy,
          panelStyle,
          maxLines: maxLines,
        ),
        holdings,
        _minimumTextWidthForLines(
          context,
          l10n.jma_voting_usable_jma_votes,
          panelStyle,
          maxLines: maxLines,
        ),
        usableRegular + usableBonus,
      ].reduce(math.max);

  final daily =
      h(8) * 2 +
      16 +
      h(8) +
      _minimumTextWidthForLines(
        context,
        l10n.jma_voting_daily_limit_remaining(5, 5),
        PicnicUi.text(size: 12, weight: FontWeight.w600),
        maxLines: maxLines,
      );

  final adminBadge =
      h(4) * 2 +
      _naturalTextWidth(
        context,
        'Admin',
        PicnicUi.text(size: 10, weight: FontWeight.w600),
      );
  final calculation =
      h(8) * 2 +
      h(12) * 2 +
      20 +
      h(4) +
      adminBadge +
      h(8) +
      _minimumTextWidthForLines(
        context,
        _jmaCalculation,
        PicnicUi.text(size: 12, weight: FontWeight.w500),
        maxLines: maxLines,
      );

  final generalFloor = math.max(generalIdentityFloor, generalBalance);
  final generalPreferred = math.max(generalIdentityPreferred, generalBalance);
  final jmaFloor = <double>[
    jmaIdentityFloor,
    badge,
    jmaBalancePanel,
    daily,
    calculation,
  ].reduce(math.max);
  final jmaPreferred = <double>[
    jmaIdentityPreferred,
    badge,
    jmaBalancePanel,
    daily,
    calculation,
  ].reduce(math.max);
  final parts = <String, double>{
    'generalIdentityFloor': generalIdentityFloor,
    'generalIdentityPreferred': generalIdentityPreferred,
    'generalBalance': generalBalance,
    'jmaIdentityFloor': jmaIdentityFloor,
    'jmaIdentityPreferred': jmaIdentityPreferred,
    'jmaBadge': badge,
    'jmaBalancePanel': jmaBalancePanel,
    'jmaDailyLimit': daily,
    'jmaCalculation': calculation,
  };
  final combinedFloor = math.max(generalFloor, jmaFloor);
  final combinedPreferred = math.max(generalPreferred, jmaPreferred);
  final controlling = parts.entries
      .reduce((left, right) => left.value >= right.value ? left : right)
      .key;
  return _LeftMeasurement(
    generalFloor: generalFloor,
    generalPreferred: generalPreferred,
    jmaFloor: jmaFloor,
    jmaPreferred: jmaPreferred,
    combinedFloor: combinedFloor,
    combinedPreferred: combinedPreferred,
    controlling: controlling,
    parts: parts,
  );
}

Map<String, double> _measureCards({
  required _LeftMeasurement left,
  required _RightMeasurement right,
  required _HorizontalGeometry geometry,
}) {
  final horizontalPadding = _horizontal(16, geometry);
  final fixed =
      largePopupCardBorderWidth() * 2 +
      horizontalPadding * 2 +
      math.max(left.generalFloor + right.general, left.jmaFloor + right.jma);
  // PICNIC-2697: JMA is out of scope for now, so the general dialog alone
  // decides the two-column minimum. Kept beside the combined figure so the
  // two can be compared without re-running with a different harness.
  final generalOnlyFixed =
      largePopupCardBorderWidth() * 2 +
      horizontalPadding * 2 +
      left.generalFloor +
      right.general;
  return <String, double>{
    for (final gap in _columnGaps) '${gap.toInt()}': fixed + gap,
    for (final gap in _columnGaps)
      'general${gap.toInt()}': generalOnlyFixed + gap,
    for (final gap in _columnGaps)
      'generalNoHint${gap.toInt()}':
          largePopupCardBorderWidth() * 2 +
          horizontalPadding * 2 +
          left.generalFloor +
          right.generalNoHint +
          gap,
  };
}

Widget _useAllProbe(AppLocalizations l10n, _HorizontalGeometry geometry) {
  double h(double value) => _horizontal(value, geometry);
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
    child: Row(
      children: [
        const Icon(Icons.check_box_outline_blank, size: 20),
        SizedBox(width: h(4)),
        Flexible(
          child: Text(
            l10n.jma_voting_use_all,
            style: PicnicUi.text(size: 14, weight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget _inputProbe(_HorizontalGeometry geometry) {
  double h(double value) => _horizontal(value, geometry);
  return Container(
    constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
    padding: EdgeInsets.only(right: h(4)),
    decoration: BoxDecoration(
      border: Border.all(width: 2),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: h(24),
              vertical: PicnicUi.vertical(8),
            ),
            child: Text(
              _editableAmount,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: PicnicUi.text(size: 16, weight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(
          width: PicnicUi.minimumTapTarget,
          height: PicnicUi.minimumTapTarget,
          child: Icon(Icons.clear, size: 20),
        ),
      ],
    ),
  );
}

Widget _submitProbe(AppLocalizations l10n, _HorizontalGeometry geometry) {
  double h(double value) => _horizontal(value, geometry);
  return Container(
    constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
    padding: EdgeInsets.symmetric(
      horizontal: h(12),
      vertical: PicnicUi.vertical(4),
    ),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.how_to_vote, size: 20),
        SizedBox(width: h(8)),
        Flexible(
          child: Text(
            l10n.label_button_vote,
            textAlign: TextAlign.center,
            style: PicnicUi.text(size: 18, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Widget _hintProbe(_HorizontalGeometry geometry) {
  double h(double value) => _horizontal(value, geometry);
  return Padding(
    padding: EdgeInsets.only(left: h(24)),
    child: Text(
      _jmaVoteHint,
      style: PicnicUi.text(size: 12, weight: FontWeight.w600),
    ),
  );
}

Widget _validationProbe(AppLocalizations l10n, _HorizontalGeometry geometry) {
  double h(double value) => _horizontal(value, geometry);
  final validation = l10n.jma_voting_max_votes_exceeded(105);
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: h(12),
      vertical: PicnicUi.vertical(8),
    ),
    decoration: BoxDecoration(border: Border.all(width: 1)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: kJmaValidationIconSide,
          height: kJmaValidationIconSide,
          child: Icon(Icons.warning_rounded, size: 16),
        ),
        SizedBox(width: h(8)),
        Expanded(
          child: Text(
            validation,
            style: PicnicUi.text(size: 12, weight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _KeyboardComponentCanvas extends StatelessWidget {
  const _KeyboardComponentCanvas({
    required this.rightWidth,
    required this.inputWidth,
    required this.submitWidth,
    required this.geometry,
  });

  final double rightWidth;
  final double inputWidth;
  final double submitWidth;
  final _HorizontalGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: const Key('use-all-probe'),
              width: rightWidth,
              child: _useAllProbe(l10n, geometry),
            ),
            SizedBox(
              key: const Key('input-probe'),
              width: inputWidth,
              child: _inputProbe(geometry),
            ),
            SizedBox(
              key: const Key('submit-probe'),
              width: submitWidth,
              child: _submitProbe(l10n, geometry),
            ),
            SizedBox(
              key: const Key('hint-probe'),
              width: rightWidth,
              child: _hintProbe(geometry),
            ),
            SizedBox(
              key: const Key('validation-probe'),
              width: rightWidth,
              child: _validationProbe(l10n, geometry),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, Object> _keyboardLayouts({
  required double bodyHeight,
  required double rightWidth,
  required double useAllHeight,
  required double inputHeight,
  required double submitHeight,
  required double feedbackHeight,
  required _RightMeasurement right,
}) {
  final verticalPadding = PicnicUi.vertical(8) * 2;
  final smallGap = PicnicUi.vertical(4);
  final pairHeight = math.max(inputHeight, submitHeight);
  final generalPairWidth =
      right.parts['generalInput']! + 8 + right.parts['generalButton']!;
  final jmaPairWidth =
      right.parts['jmaInput']! + 8 + right.parts['jmaActiveButton']!;
  final pairWidth = math.max(generalPairWidth, jmaPairWidth);
  final useAndFeedbackWidth =
      right.parts['jmaCheck']! + 8 + right.parts['jmaHint']!;
  final allControlsWidth = math.max(
    right.parts['generalCheck']! + 8 + generalPairWidth,
    right.parts['jmaCheck']! + 8 + jmaPairWidth,
  );

  Map<String, Object> result(double height, bool widthFits) => <String, Object>{
    'height': _round(height),
    'heightFits': height <= bodyHeight + 0.01,
    'widthFits': widthFits,
    'opens': height <= bodyHeight + 0.01 && widthFits,
  };

  return <String, Object>{
    'bodyHeight': _round(bodyHeight),
    'rightWidth': _round(rightWidth),
    'contractStack': result(
      verticalPadding +
          useAllHeight +
          smallGap +
          pairHeight +
          smallGap +
          feedbackHeight,
      rightWidth >= math.max(pairWidth, right.combined),
    ),
    'useAndFeedbackTopRow': result(
      verticalPadding +
          math.max(useAllHeight, feedbackHeight) +
          smallGap +
          pairHeight,
      rightWidth >= math.max(pairWidth, useAndFeedbackWidth),
    ),
    'useAllInLeftColumn': result(
      verticalPadding +
          math.max(useAllHeight, pairHeight + smallGap + feedbackHeight),
      rightWidth >= math.max(pairWidth, right.parts['jmaHint']!),
    ),
    'feedbackInLeftColumn': result(
      verticalPadding +
          math.max(feedbackHeight, useAllHeight + smallGap + pairHeight),
      rightWidth >= math.max(pairWidth, right.parts['jmaCheck']!),
    ),
    'useAndFeedbackInLeftColumn': result(
      verticalPadding +
          math.max(useAllHeight + smallGap + feedbackHeight, pairHeight),
      rightWidth >= pairWidth,
    ),
    'allControlsOneRow': result(
      verticalPadding +
          math.max(useAllHeight, math.max(inputHeight, submitHeight)) +
          smallGap +
          feedbackHeight,
      rightWidth >= allControlsWidth,
    ),
    'componentHeights': <String, double>{
      'useAll': _round(useAllHeight),
      'input': _round(inputHeight),
      'submit': _round(submitHeight),
      'feedback': _round(feedbackHeight),
      'inlinePair': _round(pairHeight),
    },
    'pairMinimumWidth': _round(pairWidth),
  };
}

void _emit(String section, Map<String, Object> value) {
  debugPrint('PICNIC2697_$section ${jsonEncode(value)}', wrapWidth: 20000);
}

Map<String, Object> _compactWidthRow(Map<String, Object> row) {
  final localOneLine = row['local_1line']! as Map<String, Object>;
  final localTwoLine = row['local_2line']! as Map<String, Object>;
  final inheritedTwoLine = row['inherited_2line']! as Map<String, Object>;
  final rightOne = localOneLine['right']! as Map<String, Object>;
  final rightTwo = localTwoLine['right']! as Map<String, Object>;
  final shortLeftOne = localOneLine['shortLeft']! as Map<String, Object>;
  final shortLeftTwo = localTwoLine['shortLeft']! as Map<String, Object>;
  final longLeftOne = localOneLine['longLeft']! as Map<String, Object>;
  final longLeftTwo = localTwoLine['longLeft']! as Map<String, Object>;

  List<Object> values(
    Map<String, Object> measurement,
    List<String> fields,
    List<String> partFields,
  ) {
    final parts = measurement['parts']! as Map<String, double>;
    return <Object>[
      for (final field in fields) measurement[field]!,
      for (final field in partFields) parts[field]!,
    ];
  }

  return <String, Object>{
    'locale': row['locale']!,
    'scale': row['scale']!,
    'r1': values(
      rightOne,
      const ['general', 'jma', 'combined'],
      const [
        'generalCheck',
        'jmaCheck',
        'generalInput',
        'jmaInput',
        'generalButton',
        'jmaActiveButton',
        'jmaHint',
      ],
    ),
    'r2': values(
      rightTwo,
      const ['general', 'jma', 'combined'],
      const [
        'generalCheck',
        'jmaCheck',
        'generalInput',
        'jmaInput',
        'generalButton',
        'jmaActiveButton',
        'jmaHint',
      ],
    ),
    's1': values(
      shortLeftOne,
      const ['generalFloor', 'jmaFloor', 'combinedFloor'],
      const [
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'generalBalance',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
        'jmaBadge',
        'jmaBalancePanel',
        'jmaDailyLimit',
        'jmaCalculation',
      ],
    ),
    's2': values(
      shortLeftTwo,
      const ['generalFloor', 'jmaFloor', 'combinedFloor'],
      const [
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'generalBalance',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
        'jmaBadge',
        'jmaBalancePanel',
        'jmaDailyLimit',
        'jmaCalculation',
      ],
    ),
    'l1': values(
      longLeftOne,
      const ['generalFloor', 'jmaFloor', 'combinedFloor'],
      const [
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
      ],
    ),
    'l2': values(
      longLeftTwo,
      const ['generalFloor', 'jmaFloor', 'combinedFloor'],
      const [
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
      ],
    ),
    'c2': <double>[
      for (final gap in <String>['16', '24', '32'])
        (localTwoLine['shortCards']! as Map<String, double>)[gap]!,
      (localTwoLine['longCards']! as Map<String, double>)['16']!,
      (inheritedTwoLine['shortCards']! as Map<String, double>)['16']!,
    ],
  };
}

List<Map<String, Object>> _summarizeKeyboard(List<Map<String, Object>> rows) {
  const layoutNames = <String>[
    'contractStack',
    'useAndFeedbackTopRow',
    'useAllInLeftColumn',
    'feedbackInLeftColumn',
    'useAndFeedbackInLeftColumn',
    'allControlsOneRow',
  ];
  final result = <Map<String, Object>>[];

  for (final viewport in <String>['851x393', '926x428']) {
    for (final scale in _textScales) {
      final matching = rows
          .where((row) => row['viewport'] == viewport && row['scale'] == scale)
          .toList();
      for (final chrome in <String>['hiddenClose', 'topClose']) {
        for (final state in <String>['hint', 'validation']) {
          final stateKey = '$chrome${state == 'hint' ? 'Hint' : 'Validation'}';
          final layoutSummary = <String, Object>{};
          for (final layoutName in layoutNames) {
            final layouts = matching
                .map(
                  (row) =>
                      (row[stateKey]! as Map<String, Object>)[layoutName]!
                          as Map<String, Object>,
                )
                .toList();
            final heights = layouts
                .map((layout) => layout['height']! as double)
                .toList();
            List<String> localesWhere(String key) => <String>[
              for (var index = 0; index < matching.length; index += 1)
                if (layouts[index][key]! as bool)
                  matching[index]['locale']! as String,
            ];
            layoutSummary[layoutName] = <Object>[
              _round(heights.reduce(math.min)),
              _round(heights.reduce(math.max)),
              localesWhere('heightFits').length,
              localesWhere('widthFits').length,
              localesWhere('opens').join(','),
            ];
          }
          final minimumCardWidths = matching
              .map((row) => row['minimumCardWidth']! as double)
              .toList();
          final firstLayouts = matching.first[stateKey]! as Map<String, Object>;
          result.add(<String, Object>{
            'viewport': viewport,
            'scale': scale,
            'chrome': chrome,
            'state': state,
            'bodyHeight': firstLayouts['bodyHeight']!,
            'cardWidth': matching.first['cardWidth']!,
            'minimumCardWidthMin': _round(minimumCardWidths.reduce(math.min)),
            'minimumCardWidthMax': _round(minimumCardWidths.reduce(math.max)),
            'columnsFit': <String>[
              for (final row in matching)
                if (row['columnsFitWidth']! as bool) row['locale']! as String,
            ],
            'layouts': layoutSummary,
          });
        }
      }
    }
  }
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadTestFonts();
    await loadPicnicUiTestFontWeights();
  });

  setUp(initTestColors);

  testWidgets('PICNIC-2697 measures widths and keyboard layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final widthRows = <Map<String, Object>>[];
    final summary = <String, double>{
      'localTwoLineShortGap16': 0,
      'inheritedTwoLineShortGap16': 0,
      'localOneLineShortGap16': 0,
      'localTwoLineLongGap16': 0,
      'generalOnlyTwoLineShortGap16': 0,
      'generalOnlyTwoLineLongGap16': 0,
      'generalOnlyOneLineShortGap16': 0,
      'generalNoHintTwoLineShortGap16': 0,
    };
    _emit('WIDTH_SCHEMA', <String, Object>{
      'r': <String>[
        'general',
        'jma',
        'combined',
        'generalCheck',
        'jmaCheck',
        'generalInput',
        'jmaInput',
        'generalButton',
        'jmaActiveButton',
        'jmaHint',
      ],
      's': <String>[
        'generalFloor',
        'jmaFloor',
        'combinedFloor',
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'generalBalance',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
        'jmaBadge',
        'jmaBalancePanel',
        'jmaDailyLimit',
        'jmaCalculation',
      ],
      'l': <String>[
        'generalFloor',
        'jmaFloor',
        'combinedFloor',
        'generalIdentityFloor',
        'generalIdentityPreferred',
        'jmaIdentityFloor',
        'jmaIdentityPreferred',
      ],
      'c2': <String>[
        'shortGap16',
        'shortGap24',
        'shortGap32',
        'longGap16',
        'inheritedShortGap16',
      ],
    });

    for (final locale in _locales) {
      for (final scale in _textScales) {
        tester.view.physicalSize = Size(
          _measurementViewport.width * 3,
          _measurementViewport.height * 3,
        );
        await tester.pumpWidget(
          buildTestApp(
            const SizedBox(key: Key('measurement-context')),
            locale: Locale(locale),
            textScaler: TextScaler.linear(scale),
            designSize: kAppDesignSize,
            splitScreenMode: kAppSplitScreenMode,
          ),
        );
        final context = tester.element(
          find.byKey(const Key('measurement-context')),
        );
        final l10n = AppLocalizations.of(context);

        final row = <String, Object>{'locale': locale, 'scale': scale};
        for (final geometry in _HorizontalGeometry.values) {
          for (final lines in <int>[1, 2]) {
            final right = _measureRight(
              context,
              l10n,
              maxLines: lines,
              geometry: geometry,
            );
            final shortLeft = _measureLeft(
              context,
              l10n,
              locale: locale,
              longNames: false,
              maxLines: lines,
              geometry: geometry,
            );
            final longLeft = _measureLeft(
              context,
              l10n,
              locale: locale,
              longNames: true,
              maxLines: lines,
              geometry: geometry,
            );
            final shortCards = _measureCards(
              left: shortLeft,
              right: right,
              geometry: geometry,
            );
            final longCards = _measureCards(
              left: longLeft,
              right: right,
              geometry: geometry,
            );
            final expectedShortGap16 =
                largePopupCardBorderWidth() * 2 +
                _horizontal(16, geometry) * 2 +
                16 +
                math.max(
                  shortLeft.generalFloor + right.general,
                  shortLeft.jmaFloor + right.jma,
                );
            expect(
              shortCards['16'],
              closeTo(expectedShortGap16, 0.01),
              reason: '일반/JMA 열 폭은 같은 다이얼로그끼리 합산해야 한다.',
            );
            final key = '${geometry.name}_${lines}line';
            row[key] = <String, Object>{
              'right': right.toJson(),
              'shortLeft': shortLeft.toJson(),
              'longLeft': longLeft.toJson(),
              'shortCards': shortCards.map(
                (gap, value) => MapEntry(gap, _round(value)),
              ),
              'longCards': longCards.map(
                (gap, value) => MapEntry(gap, _round(value)),
              ),
            };

            expect(right.combined, greaterThan(0));
            expect(shortLeft.combinedFloor, greaterThan(0));
            expect(longLeft.combinedFloor, greaterThan(0));
            if (lines == 2) {
              final oneLine =
                  row['${geometry.name}_1line']! as Map<String, Object>;
              final oneLineRight = oneLine['right']! as Map<String, Object>;
              expect(
                right.combined,
                lessThanOrEqualTo((oneLineRight['combined']! as double) + 0.01),
              );
            }

            final summaryKey = switch ((geometry, lines)) {
              (_HorizontalGeometry.local, 2) => 'localTwoLineShortGap16',
              (_HorizontalGeometry.inherited, 2) =>
                'inheritedTwoLineShortGap16',
              (_HorizontalGeometry.local, 1) => 'localOneLineShortGap16',
              _ => null,
            };
            if (summaryKey != null) {
              summary[summaryKey] = math.max(
                summary[summaryKey]!,
                shortCards['16']!,
              );
            }
            if (geometry == _HorizontalGeometry.local && lines == 2) {
              summary['localTwoLineLongGap16'] = math.max(
                summary['localTwoLineLongGap16']!,
                longCards['16']!,
              );
            }

            // PICNIC-2697: JMA is out of scope for now. Track the same three
            // figures for the general dialog alone, so the two-column minimum
            // can be read without the JMA panels that dominate it.
            if (geometry == _HorizontalGeometry.local) {
              final generalKey = lines == 2
                  ? 'generalOnlyTwoLineShortGap16'
                  : 'generalOnlyOneLineShortGap16';
              summary[generalKey] = math.max(
                summary[generalKey]!,
                shortCards['general16']!,
              );
              if (lines == 2) {
                summary['generalOnlyTwoLineLongGap16'] = math.max(
                  summary['generalOnlyTwoLineLongGap16']!,
                  longCards['general16']!,
                );
                summary['generalNoHintTwoLineShortGap16'] = math.max(
                  summary['generalNoHintTwoLineShortGap16']!,
                  shortCards['generalNoHint16']!,
                );
              }
            }
          }
        }

        // Reuse the production height helper on every shaping context. This
        // also guards against accidentally measuring with a different scaler.
        final productionHeight = measureVotingTextHeight(
          context,
          l10n.label_button_vote,
          PicnicUi.text(size: 18, weight: FontWeight.w700),
          maxWidth: 240,
        );
        expect(productionHeight, greaterThan(0));
        widthRows.add(row);
        _emit('WIDTH', _compactWidthRow(row));
      }
    }

    _emit(
      'CARD_SUMMARY',
      summary.map((key, value) => MapEntry(key, _round(value))),
    );
    expect(widthRows, hasLength(_locales.length * _textScales.length));

    final keyboardRows = <Map<String, Object>>[];
    for (final viewport in <Size>[const Size(851, 393), const Size(926, 428)]) {
      for (final locale in _locales) {
        for (final scale in _textScales) {
          tester.view.physicalSize = Size(
            viewport.width * 3,
            viewport.height * 3,
          );
          await tester.pumpWidget(
            buildTestApp(
              const SizedBox(key: Key('keyboard-context')),
              locale: Locale(locale),
              textScaler: TextScaler.linear(scale),
              designSize: kAppDesignSize,
              splitScreenMode: kAppSplitScreenMode,
            ),
          );
          var context = tester.element(
            find.byKey(const Key('keyboard-context')),
          );
          final l10n = AppLocalizations.of(context);
          final right = _measureRight(
            context,
            l10n,
            maxLines: 2,
            geometry: _HorizontalGeometry.local,
          );
          final left = _measureLeft(
            context,
            l10n,
            locale: locale,
            longNames: false,
            maxLines: 2,
            geometry: _HorizontalGeometry.local,
          );

          final routeWidth = viewport.width - PicnicUi.horizontal(16) * 2;
          final cardWidth = math.min(routeWidth, 800.0);
          final columnSpace = math.max(
            0,
            cardWidth -
                largePopupCardBorderWidth() * 2 -
                16 * 2 -
                _columnGaps.first,
          );
          var rightWidth = columnSpace * 0.6;
          if (columnSpace >= left.combinedFloor + right.combined) {
            final leftWidth = (columnSpace * 0.4).clamp(
              left.combinedFloor,
              columnSpace - right.combined,
            );
            rightWidth = columnSpace - leftWidth;
          }
          final inputWidth = right.parts['jmaInput']!;
          final submitWidth = right.parts['jmaActiveButton']!;

          await tester.pumpWidget(
            buildTestApp(
              _KeyboardComponentCanvas(
                rightWidth: rightWidth,
                inputWidth: inputWidth,
                submitWidth: submitWidth,
                geometry: _HorizontalGeometry.local,
              ),
              locale: Locale(locale),
              textScaler: TextScaler.linear(scale),
              designSize: kAppDesignSize,
              splitScreenMode: kAppSplitScreenMode,
            ),
          );
          context = tester.element(find.byKey(const Key('use-all-probe')));
          final useAllHeight = tester
              .getSize(find.byKey(const Key('use-all-probe')))
              .height;
          final inputHeight = tester
              .getSize(find.byKey(const Key('input-probe')))
              .height;
          final submitHeight = tester
              .getSize(find.byKey(const Key('submit-probe')))
              .height;
          final hintHeight = tester
              .getSize(find.byKey(const Key('hint-probe')))
              .height;
          final validationHeight = tester
              .getSize(find.byKey(const Key('validation-probe')))
              .height;
          expect(
            find.descendant(
              of: find.byKey(const Key('hint-probe')),
              matching: find.text(l10n.jma_voting_max_votes_exceeded(105)),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);

          final hiddenCloseBodyHeight =
              viewport.height -
              280 -
              kVoteDialogMinimumVerticalInset * 2 -
              largePopupHiddenChromeHeight();
          final topCloseBodyHeight = math.max(
            0.0,
            hiddenCloseBodyHeight - _topCloseExtraChromeHeight,
          );
          final hiddenCloseHint = _keyboardLayouts(
            bodyHeight: hiddenCloseBodyHeight,
            rightWidth: rightWidth,
            useAllHeight: useAllHeight,
            inputHeight: inputHeight,
            submitHeight: submitHeight,
            feedbackHeight: hintHeight,
            right: right,
          );
          final hiddenCloseValidation = _keyboardLayouts(
            bodyHeight: hiddenCloseBodyHeight,
            rightWidth: rightWidth,
            useAllHeight: useAllHeight,
            inputHeight: inputHeight,
            submitHeight: submitHeight,
            feedbackHeight: validationHeight,
            right: right,
          );
          expect(
            hiddenCloseHint['pairMinimumWidth'],
            closeTo(
              _round(
                math.max(
                  right.parts['generalInput']! +
                      8 +
                      right.parts['generalButton']!,
                  right.parts['jmaInput']! +
                      8 +
                      right.parts['jmaActiveButton']!,
                ),
              ),
              0.01,
            ),
            reason: 'inline pair 폭은 일반/JMA 중 더 넓은 다이얼로그를 써야 한다.',
          );
          final topCloseHint = _keyboardLayouts(
            bodyHeight: topCloseBodyHeight,
            rightWidth: rightWidth,
            useAllHeight: useAllHeight,
            inputHeight: inputHeight,
            submitHeight: submitHeight,
            feedbackHeight: hintHeight,
            right: right,
          );
          final topCloseValidation = _keyboardLayouts(
            bodyHeight: topCloseBodyHeight,
            rightWidth: rightWidth,
            useAllHeight: useAllHeight,
            inputHeight: inputHeight,
            submitHeight: submitHeight,
            feedbackHeight: validationHeight,
            right: right,
          );
          final minimumCardWidth = _measureCards(
            left: left,
            right: right,
            geometry: _HorizontalGeometry.local,
          )['16']!;
          final row = <String, Object>{
            'viewport': '${viewport.width.toInt()}x${viewport.height.toInt()}',
            'locale': locale,
            'scale': scale,
            'cardWidth': _round(cardWidth),
            'minimumCardWidth': _round(minimumCardWidth),
            'columnsFitWidth': cardWidth >= minimumCardWidth,
            'hiddenCloseHint': hiddenCloseHint,
            'hiddenCloseValidation': hiddenCloseValidation,
            'topCloseHint': topCloseHint,
            'topCloseValidation': topCloseValidation,
          };
          keyboardRows.add(row);

          // The rendered components are the source for the layout heights.
          // Existing helpers cross-check the same typography and scaling.
          expect(inputHeight, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
          expect(submitHeight, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
          expect(
            hintHeight,
            greaterThanOrEqualTo(
              _textHeight(
                context,
                _jmaVoteHint,
                PicnicUi.text(size: 12, weight: FontWeight.w600),
                maxWidth: rightWidth,
              ),
            ),
          );
          expect(validationHeight, greaterThanOrEqualTo(20));
          expect(
            jmaValidationBandHeight(
              context,
              message: l10n.jma_voting_max_votes_exceeded(105),
              contentWidth: rightWidth,
            ),
            greaterThan(0),
          );
        }
      }
    }
    expect(keyboardRows, hasLength(42));
    _emit('KEYBOARD_SCHEMA', <String, Object>{
      'layoutValues': <String>[
        'heightMin',
        'heightMax',
        'heightFitLocaleCount',
        'widthFitLocaleCount',
        'openLocales',
      ],
    });
    for (final row in _summarizeKeyboard(keyboardRows)) {
      _emit('KEYBOARD_SUMMARY', row);
    }
    _emit(
      'FINAL_SUMMARY',
      summary.map((key, value) => MapEntry(key, _round(value))),
    );

    // Public production widget contracts used by the planning formulas stay
    // executable under the same ScreenUtil setup.
    tester.view.physicalSize = const Size(851 * 3, 393 * 3);
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) => SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  key: Key('production-check'),
                  width: 320,
                  child: VotingCheckAllOption(checkAll: false, onToggle: _noop),
                ),
                const VotingSubmitButton(
                  key: Key('production-submit'),
                  canVote: true,
                  isVoting: false,
                ),
                SizedBox(
                  key: const Key('production-member'),
                  width: 320,
                  child: VotingMemberInfo(voteItemModel: MockData.voteItem()),
                ),
              ],
            ),
          ),
        ),
        locale: const Locale('ko'),
        textScaler: const TextScaler.linear(2),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    final helperContext = tester.element(
      find.byKey(const Key('production-check')),
    );
    expect(
      tester.getSize(find.byKey(const Key('production-check'))).height,
      lessThanOrEqualTo(
        VotingCheckAllOption.preferredHeight(helperContext, maxWidth: 320) +
            0.5,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('production-submit'))).width,
      closeTo(VotingSubmitButton.preferredWidth(), 0.5),
    );
    expect(
      tester.getSize(find.byKey(const Key('production-submit'))).height,
      lessThanOrEqualTo(
        VotingSubmitButton.preferredHeight(helperContext) + 0.5,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
