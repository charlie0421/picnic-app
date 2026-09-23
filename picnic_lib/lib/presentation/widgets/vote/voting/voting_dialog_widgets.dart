import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

/// The height a [Text] with [style] takes at [maxWidth] in this [context]:
/// same scaler, direction and locale as the widget would resolve.
double measureVotingTextHeight(
  BuildContext context,
  String text,
  TextStyle style, {
  required double maxWidth,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: math.max(0.0, maxWidth));
  final height = painter.height;
  painter.dispose();
  return height;
}

/// The narrowest width at which [text] stays within [maxLines].
///
/// A natural one-line width is used when it fits. Otherwise a bounded binary
/// search finds the width needed for at most two lines, using the same locale,
/// direction and text scaler as the rendered label.
double measureVotingTextMinimumWidth(
  BuildContext context,
  String text,
  TextStyle style, {
  required int maxLines,
}) {
  if (text.isEmpty) return 0;
  final natural = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final naturalWidth = natural.width;
  natural.dispose();
  if (maxLines <= 1) return naturalWidth;

  bool fits(double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: width);
    final result =
        !painter.didExceedMaxLines &&
        painter.computeLineMetrics().length <= maxLines;
    painter.dispose();
    return result;
  }

  var low = 0.0;
  var high = naturalWidth;
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

final class _CacheOnlyImageMiss implements Exception {
  const _CacheOnlyImageMiss();
}

/// Shows the already-decoded vote-detail portrait, and never fetches it.
///
/// This widget is used only as [PicnicCachedNetworkImage.placeholder]. The
/// popup's full-quality request still starts immediately; a completed 78px
/// detail entry can cover the loading interval without creating another disk
/// or network request when that entry is missing, pending, or evicted.
class VoteDetailPortraitCachePlaceholder extends StatefulWidget {
  const VoteDetailPortraitCachePlaceholder({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final BoxFit fit;

  @override
  State<VoteDetailPortraitCachePlaceholder> createState() =>
      _VoteDetailPortraitCachePlaceholderState();
}

class _VoteDetailPortraitCachePlaceholderState
    extends State<VoteDetailPortraitCachePlaceholder> {
  ImageInfo? _imageInfo;
  ImageStreamCompleter? _completer;
  ImageStreamListener? _listener;
  int _generation = 0;
  bool _isStartingLookup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startLookup();
  }

  @override
  void didUpdateWidget(VoteDetailPortraitCachePlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _startLookup();
    }
  }

  void _startLookup() {
    final generation = ++_generation;
    _releaseCachedImage();
    if (widget.imageUrl.trim().isEmpty) return;

    _isStartingLookup = true;
    try {
      final request = resolveVoteDetailPortraitImageRequest(
        context: context,
        imageUrl: widget.imageUrl,
      );
      final configuration = createLocalImageConfiguration(
        context,
        size: const Size(
          voteDetailPortraitLogicalSize,
          voteDetailPortraitLogicalSize,
        ),
      );
      request.obtainKey(configuration).then<void>((key) {
        if (!_isCurrentGeneration(generation)) return;
        _adoptCompletedCacheEntry(key, generation);
      }, onError: (Object _, StackTrace _) {});
    } on Object {
      // Invalid sources stay on the same loading placeholder. In particular,
      // this cache-only path must never fall back to resolving the provider.
    } finally {
      _isStartingLookup = false;
    }
  }

  void _adoptCompletedCacheEntry(Object key, int generation) {
    final cache = PaintingBinding.instance.imageCache;
    final completer = cache.putIfAbsent(
      key,
      () => throw const _CacheOnlyImageMiss(),
      onError: (Object _, StackTrace? _) {},
    );
    if (completer == null || !_isCurrentGeneration(generation)) return;

    // Reject pending or uncached entries. putIfAbsent can also promote a
    // decoded live entry back into keepAlive; that completed image is reusable.
    final status = cache.statusForKey(key);
    if (status.pending || !status.keepAlive) return;

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) => _acceptImage(info, completer, listener, generation),
      onError: (Object _, StackTrace? _) {
        _dropFailedCompleter(completer, listener, generation);
      },
    );
    _completer = completer;
    _listener = listener;
    try {
      completer.addListener(listener);
    } on StateError {
      // An entry evicted between lookup and attachment remains a cache miss.
      if (identical(_completer, completer) && identical(_listener, listener)) {
        _completer = null;
        _listener = null;
      }
    }
  }

  void _acceptImage(
    ImageInfo info,
    ImageStreamCompleter completer,
    ImageStreamListener listener,
    int generation,
  ) {
    if (!_isCurrentGeneration(generation) ||
        !identical(_completer, completer) ||
        !identical(_listener, listener)) {
      info.dispose();
      return;
    }

    final previous = _imageInfo;
    if (previous != null && info.isCloneOf(previous)) {
      info.dispose();
      return;
    }
    _imageInfo = info;
    previous?.dispose();
    if (!_isStartingLookup) setState(() {});
  }

  void _dropFailedCompleter(
    ImageStreamCompleter completer,
    ImageStreamListener listener,
    int generation,
  ) {
    if (!_isCurrentGeneration(generation) ||
        !identical(_completer, completer) ||
        !identical(_listener, listener)) {
      return;
    }
    _releaseCachedImage();
    if (!_isStartingLookup) setState(() {});
  }

  bool _isCurrentGeneration(int generation) =>
      mounted && generation == _generation;

  void _releaseCachedImage() {
    final completer = _completer;
    final listener = _listener;
    _completer = null;
    _listener = null;
    if (completer != null && listener != null) {
      completer.removeListener(listener);
    }
    _imageInfo?.dispose();
    _imageInfo = null;
  }

  @override
  void dispose() {
    _generation++;
    _releaseCachedImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageInfo = _imageInfo;
    if (imageInfo == null) return buildImageLoadingOverlay();

    return RawImage(
      image: imageInfo.image,
      debugImageLabel: imageInfo.debugLabel,
      scale: imageInfo.scale,
      fit: widget.fit,
    );
  }
}

/// 아티스트 프로필 이미지
class VotingArtistImage extends StatelessWidget {
  final VoteItemModel voteItemModel;

  /// Overrides the portrait's side, for a caller that has measured a shorter
  /// budget than the default wants.
  final double? logicalSize;

  const VotingArtistImage({
    super.key,
    required this.voteItemModel,
    this.logicalSize,
  });

  /// The default design side, 80, scaled down on a narrow viewport but never
  /// up on a wide one — `.w` is the width factor and this is a vertical
  /// extent too, so a 851 wide landscape window used to render it 173 high.
  static const double defaultLogicalSize = 80;

  /// The height [build] lays out, for a caller that has to budget for it.
  static double preferredHeight({double? logicalSize}) =>
      logicalSize ?? voteDialogDecorationExtent(defaultLogicalSize);

  double _side() =>
      logicalSize ?? voteDialogDecorationExtent(defaultLogicalSize);

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if ((voteItemModel.artist?.id ?? 0) != 0) {
      imageUrl = voteItemModel.artist?.image;
    } else {
      imageUrl = voteItemModel.artistGroup?.image;
    }

    final side = _side();
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary500, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? PicnicCachedNetworkImage(
                imageUrl: imageUrl,
                width: side,
                height: side,
                cdnVariant: PicnicCdnImageVariant.avatar,
                fit: BoxFit.cover,
                placeholder: VoteDetailPortraitCachePlaceholder(
                  imageUrl: imageUrl,
                ),
                lazyLoadingStrategy: LazyLoadingStrategy.none,
                priority: ImagePriority.high,
              )
            : Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey200,
                ),
                child: Icon(
                  Icons.person,
                  size: side / 2,
                  color: AppColors.grey500,
                ),
              ),
      ),
    );
  }
}

/// 아티스트/그룹 이름 정보
class VotingMemberInfo extends StatelessWidget {
  final VoteItemModel voteItemModel;
  final bool columns;

  const VotingMemberInfo({
    super.key,
    required this.voteItemModel,
    this.columns = false,
  });

  static bool _hasArtistGroup(VoteItemModel voteItemModel) =>
      (voteItemModel.artist?.id ?? 0) != 0 &&
      voteItemModel.artist?.artistGroup?.name != null;

  static String _artistName(VoteItemModel voteItemModel) =>
      getLocaleTextFromJson(
        (voteItemModel.artist?.id ?? 0) != 0
            ? voteItemModel.artist?.name ?? {}
            : voteItemModel.artistGroup?.name ?? {},
      );

  static TextStyle _nameStyle() =>
      PicnicUi.text(size: 16, weight: FontWeight.w700);

  static TextStyle _groupStyle() =>
      PicnicUi.text(size: 12, color: PicnicUi.secondaryText);

  static double _dividerHeight() => 20.0.h;
  static double _columnNameGap() => 2.0.h;

  static double columnMinimumWidth(
    BuildContext context, {
    required VoteItemModel voteItemModel,
  }) {
    final widths = <double>[
      measureVotingTextMinimumWidth(
        context,
        _artistName(voteItemModel),
        _nameStyle(),
        maxLines: 2,
      ),
    ];
    if (_hasArtistGroup(voteItemModel)) {
      widths.add(
        measureVotingTextMinimumWidth(
          context,
          getLocaleTextFromJson(voteItemModel.artist!.artistGroup!.name),
          _groupStyle(),
          maxLines: 2,
        ),
      );
    }
    return widths.reduce(math.max);
  }

  static double columnPreferredHeight(
    BuildContext context, {
    required VoteItemModel voteItemModel,
    required double maxWidth,
  }) {
    var height = measureVotingTextHeight(
      context,
      _artistName(voteItemModel),
      _nameStyle(),
      maxWidth: maxWidth,
      maxLines: 2,
    );
    if (_hasArtistGroup(voteItemModel)) {
      height +=
          _columnNameGap() +
          measureVotingTextHeight(
            context,
            getLocaleTextFromJson(voteItemModel.artist!.artistGroup!.name),
            _groupStyle(),
            maxWidth: maxWidth,
            maxLines: 2,
          );
    }
    return height + _dividerHeight();
  }

  /// The height [build] lays out at [maxWidth], for a caller that has to
  /// budget for it before the frame.
  ///
  /// Mirrors the row below: with a group the two names share the width as
  /// equal `Flexible`s around the gap, so each wraps inside half of it.
  static double preferredHeight(
    BuildContext context, {
    required VoteItemModel voteItemModel,
    required double maxWidth,
  }) {
    final hasArtistGroup = _hasArtistGroup(voteItemModel);
    final nameWidth = hasArtistGroup
        ? math.max(0.0, (maxWidth - PicnicUi.horizontal(8)) / 2)
        : maxWidth;
    var row = measureVotingTextHeight(
      context,
      _artistName(voteItemModel),
      _nameStyle(),
      maxWidth: nameWidth,
    );
    if (hasArtistGroup) {
      row = math.max(
        row,
        measureVotingTextHeight(
          context,
          getLocaleTextFromJson(voteItemModel.artist!.artistGroup!.name),
          _groupStyle(),
          maxWidth: nameWidth,
        ),
      );
    }
    return row + _dividerHeight();
  }

  @override
  Widget build(BuildContext context) {
    final hasArtistGroup = _hasArtistGroup(voteItemModel);

    if (columns) {
      return ColoredBox(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _artistName(voteItemModel),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _nameStyle(),
              textAlign: TextAlign.start,
            ),
            if (hasArtistGroup) ...[
              SizedBox(height: _columnNameGap()),
              Text(
                getLocaleTextFromJson(voteItemModel.artist!.artistGroup!.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _groupStyle(),
                textAlign: TextAlign.start,
              ),
            ],
            Divider(
              color: AppColors.grey300,
              thickness: 1,
              height: _dividerHeight(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // A fixed 24 row cropped long artist names and every name at a large
        // text scale; the names now wrap inside the popup width instead.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _artistName(voteItemModel),
                style: _nameStyle(),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasArtistGroup) ...[
              SizedBox(width: PicnicUi.horizontal(8)),
              Flexible(
                child: Text(
                  getLocaleTextFromJson(
                    voteItemModel.artist!.artistGroup!.name,
                  ),
                  style: _groupStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        Divider(
          color: AppColors.grey300,
          thickness: 1,
          height: _dividerHeight(),
        ),
      ],
    );
  }
}

/// 파트너/기본 로고 이미지
class VotingLogoImage extends StatelessWidget {
  final VoteModel voteModel;

  const VotingLogoImage({super.key, required this.voteModel});

  static bool _showsPartner(VoteModel voteModel) {
    final partner = voteModel.partner;
    return (voteModel.isPartnership ?? false) &&
        partner != null &&
        partner.isNotEmpty;
  }

  /// The design side of the logo box: the partner logo is 100, the picnic
  /// mark 60. Both are vertical extents written with `.w`, so they are capped
  /// the same way the portrait is.
  static double logicalSize(VoteModel voteModel) =>
      voteDialogDecorationExtent(_showsPartner(voteModel) ? 100 : 60);

  /// The height [build] lays out, for a caller that has to budget for it.
  static double preferredHeight(VoteModel voteModel) => logicalSize(voteModel);

  @override
  Widget build(BuildContext context) {
    final partner = voteModel.partner;

    final side = logicalSize(voteModel);
    if (_showsPartner(voteModel) && partner != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/partners/$partner.png',
            width: side,
            height: side,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    partner.toUpperCase(),
                    style: PicnicUi.text(
                      size: 10,
                      weight: FontWeight.w700,
                      color: PicnicUi.primaryForeground,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return SizedBox(
      width: side,
      height: side,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/logo.png',
            width: side * 2 / 3,
            height: side * 2 / 3,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// 파트너십 혜택 버블
class VotingBubbleInfo extends StatelessWidget {
  final VoteModel voteModel;

  const VotingBubbleInfo({super.key, required this.voteModel});

  static TextStyle _style() => PicnicUi.text(
    size: 12,
    weight: FontWeight.w600,
    color: PicnicUi.actionColor,
  );

  /// The band the bubble needs, bubble border and all.
  ///
  /// The decoration is allowed to scroll this away, so the layout does not
  /// reserve it. A caller deciding whether it can *afford* something else —
  /// the top close strip costs 24 — needs to know what that something else
  /// would push out.
  static double preferredHeight(
    BuildContext context,
    VoteModel voteModel, {
    required double maxWidth,
  }) {
    final partner = voteModel.partner;
    final twoLines =
        (voteModel.isPartnership ?? false) &&
        partner != null &&
        partner.isNotEmpty;
    final text = twoLines
        ? '· ${AppLocalizations.of(context).voting_share_benefit_text}\n· ${partner.toUpperCase()} 파트너십 혜택'
        : '· ${AppLocalizations.of(context).voting_share_benefit_text}';
    // The bubble draws a 1.5 dashed border on both edges and a pointer above.
    return measureVotingTextHeight(
          context,
          text,
          _style(),
          maxWidth: maxWidth,
        ) +
        PicnicUi.vertical(3) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final isPartnership = voteModel.isPartnership ?? false;
    final partner = voteModel.partner;

    // BubbleBox import를 피하기 위해 간단한 Container로 대체하지 않음
    // 이 위젯은 voting_dialog.dart에서 BubbleBox와 함께 사용됨
    // → 호출부에서 BubbleBox 래핑 유지
    final style = _style();

    return Column(
      children: [
        isPartnership && partner != null && partner.isNotEmpty
            ? Text(
                '· ${AppLocalizations.of(context).voting_share_benefit_text}\n· ${partner.toUpperCase()} 파트너십 혜택',
                style: style,
                textAlign: TextAlign.center,
              )
            : Text(
                '· ${AppLocalizations.of(context).voting_share_benefit_text}',
                style: style,
              ),
      ],
    );
  }
}

/// 스타캔디 잔액 + 충전 버튼
class VotingStarCandyInfo extends StatelessWidget {
  final BigInt myStarCandy;
  final VoidCallback onRecharge;
  final bool columns;

  const VotingStarCandyInfo({
    super.key,
    required this.myStarCandy,
    required this.onRecharge,
    this.columns = false,
  });

  static const String _columnAmountFixture = '9,999,999';

  static TextStyle _amountStyle() =>
      PicnicUi.text(size: 16, weight: FontWeight.w700);

  static TextStyle _rechargeStyle() =>
      PicnicUi.text(size: 14, weight: FontWeight.w700);

  /// The 1px border the mint pill draws, which `BoxDecoration.padding` adds to
  /// the pill's box on both edges — so any width maths about the pill has to
  /// carry it.
  static const double rechargePillBorderWidth = 1;

  /// The width the pill takes when nothing squeezes it: its own label plus the
  /// border, padding, gap and icon around it.
  ///
  /// This is the geometry the balance row had before the two-column work, and
  /// it is what the one-column row hands the pill — a non-flex child sized to
  /// its content, with the balance taking everything else.
  static double rechargeContentWidth(
    BuildContext context, {
    bool columns = false,
  }) {
    final padding = columns ? 12.0 : voteDialogCardExtent(12);
    final gap = columns ? 4.0 : voteDialogCardExtent(4);
    final icon = columns ? 16.0 : voteDialogCardExtent(16);
    return rechargePillBorderWidth * 2 +
        padding * 2 +
        measureVotingTextMinimumWidth(
          context,
          AppLocalizations.of(context).label_button_recharge,
          _rechargeStyle(),
          maxLines: columns ? 2 : 1,
        ) +
        gap +
        icon;
  }

  /// The stable balance slot used by both column selection and one-column
  /// pill yielding. It deliberately does not follow the live wallet value:
  /// a refresh must not move the row or change the selected layout.
  static double amountMinimumWidth(BuildContext context) =>
      measureVotingTextMinimumWidth(
        context,
        _columnAmountFixture,
        _amountStyle(),
        maxLines: 1,
      );

  static double columnMinimumWidth(BuildContext context) {
    final amount = amountMinimumWidth(context);
    final recharge = rechargeContentWidth(context, columns: true);
    return 32 + 4 + amount + recharge;
  }

  /// The height [build] lays out at [maxWidth]: the 32 icon, the balance and
  /// the recharge button's 48 tap target, whichever is tallest.
  static double preferredHeight(
    BuildContext context, {
    required double maxWidth,
    bool columns = false,
  }) {
    final amount = measureVotingTextHeight(
      context,
      '0',
      _amountStyle(),
      maxWidth: maxWidth,
    );
    if (columns) {
      final amountWidth = amountMinimumWidth(context);
      final pillBorder = rechargePillBorderWidth * 2;
      final rechargeLabelWidth = math.max(
        0.0,
        maxWidth - 32 - 4 - amountWidth - pillBorder - 12 * 2 - 4 - 16,
      );
      final recharge = measureVotingTextHeight(
        context,
        AppLocalizations.of(context).label_button_recharge,
        _rechargeStyle(),
        maxWidth: rechargeLabelWidth,
        maxLines: 2,
      );
      return math.max(
        PicnicUi.minimumTapTarget,
        math.max(32, math.max(amount, recharge + pillBorder)),
      );
    }
    final recharge = measureVotingTextHeight(
      context,
      AppLocalizations.of(context).label_button_recharge,
      _rechargeStyle(),
      maxWidth: maxWidth,
    );
    return math.max(
      PicnicUi.minimumTapTarget,
      math.max(32, math.max(amount, recharge)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconWidth = columns ? 32.0 : 32.w;
    final amount = columns
        ? Text(
            formatWalletAmount(myStarCandy),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: _amountStyle().copyWith(color: PicnicUi.actionColor),
          )
        : Text(
            formatWalletAmount(myStarCandy),
            style: _amountStyle().copyWith(color: PicnicUi.actionColor),
          );
    final recharge = _RechargeButton(onPressed: onRecharge, columns: columns);
    final gap = columns ? 4.0 : PicnicUi.horizontal(4);
    final icon = Container(
      width: iconWidth,
      height: 32,
      alignment: Alignment.centerLeft,
      child: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/star_100.png',
        width: iconWidth,
        height: 32,
      ),
    );

    if (columns) {
      return SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: gap),
            SizedBox(
              // Keep the neutral reserved geometry stable when a wallet
              // refresh changes the value. Balances beyond the supported
              // fixture are ellipsized rather than expanding into the 48px
              // recharge target or changing the selected column count.
              width: amountMinimumWidth(context),
              child: amount,
            ),
            Expanded(child: recharge),
          ],
        ),
      );
    }

    // The pill is given an explicit width rather than a flex share.
    //
    // A flex child cannot express "size to your content, but give way when
    // there is no room": `Flexible` hands the pill half of what the icon and
    // the gap leave whether it needs it or not, and `Align` does not
    // shrink-wrap under a bounded width, so the shipped pill grew to about
    // 1.8x its content and took that width off the balance beside it. A
    // non-flex pill keeps the content width but overflows the row outright on
    // the long locales at 200%.
    //
    // Measuring the content first resolves both: the pill asks for exactly
    // what its label needs, and only past half of the remaining width does it
    // start to give way — its label ellipsizes, and a digit cannot. The
    // balance's Expanded then takes the rest, so nothing is left for
    // `spaceBetween` to spread.
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = math.max(0.0, constraints.maxWidth - iconWidth - gap);
        final pillWidth = math.min(
          rechargeContentWidth(context),
          math.max(room / 2, room - amountMinimumWidth(context)),
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: gap),
            Expanded(child: amount),
            SizedBox(width: pillWidth, child: recharge),
          ],
        );
      },
    );
  }
}

class _RechargeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool columns;

  const _RechargeButton({required this.onPressed, this.columns = false});

  @override
  Widget build(BuildContext context) {
    final iconGap = columns ? 4.0 : voteDialogCardExtent(4);
    final iconWidth = columns ? 16.0 : voteDialogCardExtent(16);
    final label = Text(
      AppLocalizations.of(context).label_button_recharge,
      // The one-column pill is sized to this label, so it never needs a second
      // line — and VotingStarCandyInfo.preferredHeight budgets for one.
      maxLines: columns ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: VotingStarCandyInfo._rechargeStyle().copyWith(
        color: PicnicUi.actionColor,
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      // The mint pill keeps its 32 visual height and the tap area its 48
      // minimum, so the surrounding row geometry stays recognisable — but both
      // are now floors rather than fixed boxes. At 200% the label alone is
      // 14 * 1.45 * 2 = 40.6 high, which a hard 32 pill simply painted
      // outside of.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: EdgeInsets.symmetric(
              horizontal: columns ? 12 : voteDialogCardExtent(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary500,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: PicnicUi.actionColor,
                width: VotingStarCandyInfo.rechargePillBorderWidth,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : iconWidth + iconGap;
                final resolvedIconWidth = math.min(iconWidth, availableWidth);
                final showGap = availableWidth >= iconWidth + iconGap;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: label),
                    if (showGap) SizedBox(width: iconGap),
                    SizedBox(
                      width: resolvedIconWidth,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/plus_style=fill.svg',
                        width: resolvedIconWidth,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          PicnicUi.actionColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 투표 제출 버튼
class VotingSubmitButton extends StatelessWidget {
  final bool canVote;
  final bool isVoting;
  final VoidCallback? onPressed;
  final bool columns;

  const VotingSubmitButton({
    super.key,
    required this.canVote,
    required this.isVoting,
    this.onPressed,
    this.columns = false,
  });

  static const double _minHeight = 52;

  /// The two-column button spans its column, so its label wraps: two lines,
  /// then an ellipsis.
  static const int _columnsMaxLabelLines = 2;

  static TextStyle _labelStyle({Color? color}) =>
      PicnicUi.text(size: 18, weight: FontWeight.w600, color: color);

  /// The height [build] lays out, for a caller that has to budget for it
  /// before the frame: the 52 minimum, or the scaled label plus padding.
  ///
  /// One column: the button is the design's fixed pill and its label is one
  /// line, scaled down when it is wider than the pill. The height therefore
  /// depends on the text scale only, never on the label's length or the
  /// width — which is what keeps a long translation from growing the button
  /// (PICNIC-2700) and keeps this budget equal to what [build] draws.
  static double preferredHeight(
    BuildContext context, {
    double? maxWidth,
    bool columns = false,
  }) {
    // The one-column height does not depend on the width, on purpose. A caller
    // passing one has the wrong mental model of this button.
    assert(columns || maxWidth == null, 'maxWidth only applies to columns');
    if (!columns) {
      return math.max(
        _minHeight,
        _oneLineLabelHeight(context) + PicnicUi.vertical(4) * 2,
      );
    }
    final label = measureVotingTextHeight(
      context,
      AppLocalizations.of(context).label_button_vote,
      _labelStyle(),
      maxWidth: (maxWidth ?? preferredWidth()) - 12.0 * 2,
      maxLines: _columnsMaxLabelLines,
    );
    return math.max(_minHeight, label + 4.0 * 2);
  }

  /// The height of the one-column label's single line at the current text
  /// scale. [build] pins the label box to exactly this, so the fit can shrink
  /// the glyphs without the button's height following them.
  static double _oneLineLabelHeight(BuildContext context) =>
      measureVotingTextHeight(
        context,
        AppLocalizations.of(context).label_button_vote,
        _labelStyle(),
        maxWidth: double.infinity,
        maxLines: 1,
      );

  static double columnMinimumWidth(BuildContext context) =>
      12 * 2 +
      measureVotingTextMinimumWidth(
        context,
        AppLocalizations.of(context).label_button_vote,
        _labelStyle(),
        maxLines: _columnsMaxLabelLines,
      );

  /// The one-column box width — the design 172, shrunk with the card when a
  /// wide window caps the capsule.
  static double preferredWidth() => voteDialogCardExtent(172);

  @override
  Widget build(BuildContext context) {
    final isEnabled = canVote && !isVoting;
    final isActive = isEnabled || isVoting;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: columns ? double.infinity : preferredWidth(),
        constraints: const BoxConstraints(minHeight: _minHeight),
        decoration: BoxDecoration(
          color: isActive ? PicnicUi.actionColor : PicnicUi.disabledSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: columns ? 12 : PicnicUi.horizontal(12),
          vertical: columns ? 4 : PicnicUi.vertical(4),
        ),
        // While a vote is in flight the label stays in the tree, hidden, and
        // the indicator sits on top of it. Swapping the label for the fixed
        // 24px indicator used to shrink the button at large text scales (7.6px
        // at 2.0x, 23.6px at 2.6x) and the dialog, which budgets the idle
        // height, jumped on submit. Keeping the label's box keeps the height
        // without measuring anything.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: !isVoting,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: columns
                  ? Text(
                      AppLocalizations.of(context).label_button_vote,
                      maxLines: _columnsMaxLabelLines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _labelStyle(
                        color: isActive
                            ? PicnicUi.onActionColor
                            : PicnicUi.secondaryText,
                      ),
                    )
                  // One line, shrunk to the pill when it is wider. The box keeps the
                  // unshrunk line's height — the same number preferredHeight budgets
                  // — so shrinking the glyphs never changes the button's height.
                  : SizedBox(
                      height: _oneLineLabelHeight(context),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppLocalizations.of(context).label_button_vote,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: _labelStyle(
                            color: isActive
                                ? PicnicUi.onActionColor
                                : PicnicUi.secondaryText,
                          ),
                        ),
                      ),
                    ),
            ),
            if (isVoting)
              const SizedBox(
                width: 24,
                height: 24,
                child: SmallPulseLoadingIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

/// 전체 사용 체크박스
class VotingCheckAllOption extends StatelessWidget {
  final bool checkAll;
  final VoidCallback onToggle;
  final bool columns;

  const VotingCheckAllOption({
    super.key,
    required this.checkAll,
    required this.onToggle,
    this.columns = false,
  });

  static const double _glyphSize = 20;

  static TextStyle _labelStyle() =>
      PicnicUi.text(size: 14, weight: FontWeight.w500);

  /// The height [build] lays out at [maxWidth]: the 48 tap minimum, or the
  /// wrapped label when a large text scale outgrows it.
  static double preferredHeight(
    BuildContext context, {
    required double maxWidth,
    bool columns = false,
  }) {
    // The glyph is a square SVG pinned to a 20px height, so it always
    // occupies 20 regardless of the width handed to it — a scaled width is
    // silently ignored. Reserve the size it actually takes, on both paths.
    const glyph = _glyphSize;
    final gap = columns ? 4.0 : PicnicUi.horizontal(4);
    final label = measureVotingTextHeight(
      context,
      AppLocalizations.of(context).label_checkbox_entire_use,
      _labelStyle(),
      maxWidth: maxWidth - glyph - gap,
      maxLines: columns ? 2 : null,
    );
    return math.max(PicnicUi.minimumTapTarget, math.max(_glyphSize, label));
  }

  static double columnMinimumWidth(BuildContext context) =>
      _glyphSize +
      4 +
      measureVotingTextMinimumWidth(
        context,
        AppLocalizations.of(context).label_checkbox_entire_use,
        _labelStyle(),
        maxLines: 2,
      );

  @override
  Widget build(BuildContext context) {
    final foreground = checkAll ? PicnicUi.actionColor : PicnicUi.secondaryText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/check_style=line.svg',
              width: _glyphSize,
              height: _glyphSize,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
            SizedBox(width: columns ? 4 : PicnicUi.horizontal(4)),
            Flexible(
              child: Text(
                AppLocalizations.of(context).label_checkbox_entire_use,
                maxLines: columns ? 2 : null,
                overflow: columns ? TextOverflow.ellipsis : null,
                style: _labelStyle().copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 충전 필요 에러 메시지
class VotingErrorMessage extends StatelessWidget {
  final bool canVote;
  final bool hasValue;
  final bool columns;

  const VotingErrorMessage({
    super.key,
    required this.canVote,
    required this.hasValue,
    this.columns = false,
  });

  static TextStyle _messageStyle() => PicnicUi.text(
    size: 12,
    weight: FontWeight.w600,
    color: AppColors.statusError,
  );

  /// The height [build] lays out at [maxWidth] — zero while the message is
  /// hidden, which is what the caller budgets for on the first frame.
  static double preferredHeight(
    BuildContext context, {
    required bool canVote,
    required bool hasValue,
    required double maxWidth,
    bool columns = false,
    bool reserveWhenHidden = false,
  }) {
    if (!reserveWhenHidden && (canVote || !hasValue)) return 0;
    final leftPadding = columns ? 24.0 : PicnicUi.horizontal(24);
    return measureVotingTextHeight(
      context,
      AppLocalizations.of(context).text_need_recharge,
      _messageStyle(),
      maxWidth: maxWidth - leftPadding,
      maxLines: columns ? 2 : null,
    );
  }

  static double columnMinimumWidth(BuildContext context) =>
      24 +
      measureVotingTextMinimumWidth(
        context,
        AppLocalizations.of(context).text_need_recharge,
        _messageStyle(),
        maxLines: 2,
      );

  @override
  Widget build(BuildContext context) {
    if (!canVote && hasValue) {
      return Container(
        padding: EdgeInsets.only(left: columns ? 24 : PicnicUi.horizontal(24)),
        width: double.infinity,
        child: Text(
          AppLocalizations.of(context).text_need_recharge,
          maxLines: columns ? 2 : null,
          overflow: columns ? TextOverflow.ellipsis : null,
          style: _messageStyle(),
          textAlign: TextAlign.left,
        ),
      );
    }
    return const SizedBox(height: 0);
  }
}

/// 입력 필드 클리어 버튼
class VotingClearButton extends StatelessWidget {
  final bool hasValue;
  final VoidCallback onClear;
  final bool columns;

  const VotingClearButton({
    super.key,
    required this.hasValue,
    required this.onClear,
    this.columns = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClear,
      // The glyph keeps its 20px size; the surrounding box is what reaches the
      // 48 minimum so the field's trailing control is actually hittable.
      child: SizedBox(
        width: PicnicUi.minimumTapTarget,
        height: PicnicUi.minimumTapTarget,
        child: Center(
          child: SvgPicture.asset(
            package: 'picnic_lib',
            'assets/icons/cancel_style=fill.svg',
            colorFilter: ColorFilter.mode(
              hasValue ? PicnicUi.ink : AppColors.grey200,
              BlendMode.srcIn,
            ),
            width: columns ? 20 : 20.w,
            height: 20,
          ),
        ),
      ),
    );
  }
}
