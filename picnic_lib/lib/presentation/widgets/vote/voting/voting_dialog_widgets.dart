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
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

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

  const VotingArtistImage({super.key, required this.voteItemModel});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if ((voteItemModel.artist?.id ?? 0) != 0) {
      imageUrl = voteItemModel.artist?.image;
    } else {
      imageUrl = voteItemModel.artistGroup?.image;
    }

    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary500, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? PicnicCachedNetworkImage(
                imageUrl: imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                placeholder: VoteDetailPortraitCachePlaceholder(
                  imageUrl: imageUrl,
                ),
                lazyLoadingStrategy: LazyLoadingStrategy.none,
                priority: ImagePriority.high,
              )
            : Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey200,
                ),
                child: Icon(Icons.person, size: 40.w, color: AppColors.grey500),
              ),
      ),
    );
  }
}

/// 아티스트/그룹 이름 정보
class VotingMemberInfo extends StatelessWidget {
  final VoteItemModel voteItemModel;

  const VotingMemberInfo({super.key, required this.voteItemModel});

  @override
  Widget build(BuildContext context) {
    final hasArtistGroup =
        (voteItemModel.artist?.id ?? 0) != 0 &&
        voteItemModel.artist?.artistGroup?.name != null;

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
                getLocaleTextFromJson(
                  (voteItemModel.artist?.id ?? 0) != 0
                      ? voteItemModel.artist?.name ?? {}
                      : voteItemModel.artistGroup?.name ?? {},
                ),
                style: PicnicUi.text(size: 16, weight: FontWeight.w700),
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
                  style: PicnicUi.text(size: 12, color: PicnicUi.secondaryText),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        Divider(color: AppColors.grey300, thickness: 1, height: 20.0.h),
      ],
    );
  }
}

/// 파트너/기본 로고 이미지
class VotingLogoImage extends StatelessWidget {
  final VoteModel voteModel;

  const VotingLogoImage({super.key, required this.voteModel});

  @override
  Widget build(BuildContext context) {
    final isPartnership = voteModel.isPartnership ?? false;
    final partner = voteModel.partner;

    if (isPartnership && partner != null && partner.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/partners/$partner.png',
            width: 100.w,
            height: 100.w,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100.w,
                height: 100.w,
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
      width: 60.w,
      height: 60.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/logo.png',
            width: 40.w,
            height: 40.w,
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

  @override
  Widget build(BuildContext context) {
    final isPartnership = voteModel.isPartnership ?? false;
    final partner = voteModel.partner;

    // BubbleBox import를 피하기 위해 간단한 Container로 대체하지 않음
    // 이 위젯은 voting_dialog.dart에서 BubbleBox와 함께 사용됨
    // → 호출부에서 BubbleBox 래핑 유지
    final style = PicnicUi.text(
      size: 12,
      weight: FontWeight.w600,
      color: PicnicUi.actionColor,
    );

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

  const VotingStarCandyInfo({
    super.key,
    required this.myStarCandy,
    required this.onRecharge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.w,
            height: 32,
            alignment: Alignment.centerLeft,
            child: Image.asset(
              package: 'picnic_lib',
              'assets/icons/store/star_100.png',
              width: 32.w,
              height: 32,
            ),
          ),
          SizedBox(width: PicnicUi.horizontal(4)),
          Expanded(
            child: Text(
              formatWalletAmount(myStarCandy),
              style: PicnicUi.text(
                size: 16,
                weight: FontWeight.w700,
                color: PicnicUi.actionColor,
              ),
            ),
          ),
          _RechargeButton(onPressed: onRecharge),
        ],
      ),
    );
  }
}

class _RechargeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RechargeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(12)),
            decoration: BoxDecoration(
              color: AppColors.secondary500,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: PicnicUi.actionColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).label_button_recharge,
                  style: PicnicUi.text(
                    size: 14,
                    weight: FontWeight.w700,
                    color: PicnicUi.actionColor,
                  ),
                ),
                SizedBox(width: PicnicUi.horizontal(4)),
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/plus_style=fill.svg',
                  width: 16.w,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    PicnicUi.actionColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
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

  const VotingSubmitButton({
    super.key,
    required this.canVote,
    required this.isVoting,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = canVote && !isVoting;
    final isActive = isEnabled || isVoting;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: 172.w,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: isActive ? PicnicUi.actionColor : PicnicUi.disabledSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(12),
          vertical: PicnicUi.vertical(4),
        ),
        child: isVoting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: SmallPulseLoadingIndicator(),
              )
            : Text(
                AppLocalizations.of(context).label_button_vote,
                textAlign: TextAlign.center,
                style: PicnicUi.text(
                  size: 18,
                  weight: FontWeight.w600,
                  color: isActive
                      ? PicnicUi.onActionColor
                      : PicnicUi.secondaryText,
                ),
              ),
      ),
    );
  }
}

/// 전체 사용 체크박스
class VotingCheckAllOption extends StatelessWidget {
  final bool checkAll;
  final VoidCallback onToggle;

  const VotingCheckAllOption({
    super.key,
    required this.checkAll,
    required this.onToggle,
  });

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
              width: 20.w,
              height: 20,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
            SizedBox(width: PicnicUi.horizontal(4)),
            Flexible(
              child: Text(
                AppLocalizations.of(context).label_checkbox_entire_use,
                style: PicnicUi.text(
                  size: 14,
                  weight: FontWeight.w500,
                  color: foreground,
                ),
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

  const VotingErrorMessage({
    super.key,
    required this.canVote,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    if (!canVote && hasValue) {
      return Container(
        padding: EdgeInsets.only(left: PicnicUi.horizontal(24)),
        width: double.infinity,
        child: Text(
          AppLocalizations.of(context).text_need_recharge,
          style: PicnicUi.text(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.statusError,
          ),
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

  const VotingClearButton({
    super.key,
    required this.hasValue,
    required this.onClear,
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
            width: 20.w,
            height: 20,
          ),
        ),
      ),
    );
  }
}
