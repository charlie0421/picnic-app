import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

enum RewardType { overview, location, size_guide }

class RewardDialog extends StatefulWidget {
  final RewardModel data;

  const RewardDialog({super.key, required this.data});

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      logger.i('data: ${widget.data}');
      return Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  buildTopSection(),
                  SizedBox(height: 67.w),
                  buildSection(RewardType.overview),
                  buildSection(RewardType.location),
                  buildSection(RewardType.size_guide),
                  SizedBox(height: 56.w),
                ],
              ),
            ),
            Positioned(
              top: 40.w,
              right: 15.w,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(
                    Icons.close,
                    color: AppColors.Grey500,
                    size: 24.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildTopSection() {
    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
              stops: [0.7, 1],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: CachedNetworkImage(
            imageUrl: widget.data != null &&
                    (widget.data.thumbnail?.contains('https') == true ||
                        widget.data.thumbnail?.contains('http') == true)
                ? widget.data.thumbnail ?? ''
                : widget.data.getCdnUrl(widget.data.thumbnail ?? ''),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width,
            placeholder: (context, url) => buildPlaceholderImage(),
            errorWidget: (context, url, error) => buildPlaceholderImage(),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 48.w,
            margin: const EdgeInsets.symmetric(horizontal: 57).r,
            child: VoteCommonTitle(
              title: widget.data.getTitle(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSection(RewardType type) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, right: 16, top: 12).r,
              padding: const EdgeInsets.only(
                      left: 24, right: 24, top: 53, bottom: 41)
                  .r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.Primary500, width: 1.5.r),
              ),
              child: Column(
                children: buildSectionContent(type),
              ),
            ),
            Positioned(
              top: 0,
              left: 40.w,
              child: Image.asset('assets/images/reward_${type.name}.png',
                  height: 24.w),
            ),
          ],
        ),
        SizedBox(height: 68.w),
      ],
    );
  }

  List<Widget> buildSectionContent(RewardType type) {
    switch (type) {
      case RewardType.overview:
        return buildImageList(widget.data.overview_images);
      case RewardType.location:
        final locale = Intl.getCurrentLocale();
        return [
          ...buildImageList(
              widget.data.location?[locale]['map'].cast<String>(),
              BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                    color: AppColors.Primary500,
                    width: 3.r,
                    strokeAlign: BorderSide.strokeAlignInside),
              )).sublist(0, 1),
          ...buildImageList(widget.data.location?[locale]['map'].cast<String>())
              .sublist(1),
          SizedBox(height: 24.w),
          ...buildTextAddress(
              widget.data.location?[locale]['address'].cast<String>(),
              getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
          SizedBox(height: 24.w),
          if (widget.data.location?[locale]['images'] != null)
            ...buildImageList(
                widget.data.location?[locale]['images'].cast<String>()),
          SizedBox(height: 24.w),
          ...buildTextList(widget.data.location?[locale]['desc'].cast<String>(),
              getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
        ];
      case RewardType.size_guide:
        final locale = Intl.getCurrentLocale();

        return widget.data.size_guide != null &&
                widget.data.size_guide?[locale] != null
            ? widget.data.size_guide![locale].map<Widget>((value) {
                // logger.i(value);
                return Column(
                  children: [
                    ...buildImageList(value['image'].cast<String>()),
                    SizedBox(height: 24.w),
                    ...buildTextList(value['desc'].cast<String>().sublist(0, 1),
                        getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
                    ...buildTextList(value['desc'].cast<String>().sublist(1),
                        getTextStyle(AppTypo.BODY16R, AppColors.Grey900)),
                    SizedBox(height: 24.w),
                  ],
                );
              }).toList()
            : [];
      default:
        return [];
    }
  }

  List<Widget> buildImageList(List<String>? images,
      [BoxDecoration? decoration]) {
    if (images == null) return [];
    List<Widget> imageWidgets = [];
    for (int i = 0; i < images.length; i++) {
      imageWidgets.add(
        Column(
          children: [
            Container(
              decoration: decoration,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: CachedNetworkImage(
                      imageUrl: widget.data.getCdnUrl(images[i]))),
            ),
            if (i != images.length - 1) SizedBox(height: 12.w),
            // 마지막 요소가 아닐 때만 추가
          ],
        ),
      );
    }
    return imageWidgets;
  }

  List<Widget> buildTextList(List<String>? texts, [TextStyle? style]) {
    if (texts == null) return [];
    return texts
        .map((e) => Text(
              e,
              style: style ?? getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
              textAlign: TextAlign.center,
            ))
        .toList();
  }

  List<Widget> buildTextAddress(List<String>? texts, [TextStyle? style]) {
    if (texts == null) return [];
    return texts
        .map((e) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Text(
                    '· $e',
                    style: style ??
                        getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: TextButton(
                    onPressed: () => copyToClipboard(
                      context,
                      e,
                    ),
                    child: Text(
                      'COPY',
                      style:
                          getTextStyle(AppTypo.BODY16B, AppColors.Primary500),
                    ),
                  ),
                ),
              ],
            ))
        .toList();
  }
}
