import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/util.dart';

enum RewardType { overview, location, sizeGuide }

class RewardDialog extends StatefulWidget {
  final RewardModel data;

  const RewardDialog({super.key, required this.data});

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.r),
      ),
      child: SizedBox(
        width: getPlatformScreenSize(context).width,
        height: getPlatformScreenSize(context).height,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  buildTopSection(),
                  const SizedBox(height: 67),
                  buildSection(RewardType.overview),
                  buildSection(RewardType.location),
                  buildSection(RewardType.sizeGuide),
                ],
              ),
            ),
            Positioned(
              top: 40,
              right: 15.cw,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(
                  'assets/icons/cancle_style=fill.svg',
                  width: 48,
                  height: 48,
                  colorFilter: ColorFilter.mode(
                    AppColors.grey200.withOpacity(0.8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopSection() {
    return Stack(
      children: [
        SizedBox(
          width: getPlatformScreenSize(context).width,
          height: getPlatformScreenSize(context).width,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
              stops: [0.7, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: PicnicCachedNetworkImage(
              imageUrl: widget.data.thumbnail ?? '',
              width: 400,
              fit: BoxFit.fill,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 48,
            margin: EdgeInsets.symmetric(horizontal: 30.cw),
            child: VoteCommonTitle(title: widget.data.getTitle()),
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
              margin: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 12),
              padding: EdgeInsets.symmetric(horizontal: 24.cw, vertical: 53),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.primary500, width: 1.5.r),
              ),
              child: Column(children: buildSectionContent(type)),
            ),
            Positioned(
              top: 0,
              left: 40.cw,
              child: Image.asset('assets/images/reward_${type.name}.png',
                  height: 24),
            ),
          ],
        ),
        const SizedBox(height: 68),
      ],
    );
  }

  List<Widget> buildSectionContent(RewardType type) {
    final locale = Intl.getCurrentLocale();
    switch (type) {
      case RewardType.overview:
        return buildImageList(widget.data.overviewImages);
      case RewardType.location:
        return [
          ...buildImageList(
              widget.data.location?[locale]['map'].cast<String>(),
              BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                    color: AppColors.primary500,
                    width: 3.r,
                    strokeAlign: BorderSide.strokeAlignInside),
              )).sublist(0, 1),
          ...buildImageList(widget.data.location?[locale]['map'].cast<String>())
              .sublist(1),
          const SizedBox(height: 24),
          ...buildTextAddress(
              widget.data.location?[locale]['address'].cast<String>(),
              getTextStyle(AppTypo.body16B, AppColors.grey900)),
          const SizedBox(height: 24),
          if (widget.data.location?[locale]['images'] != null)
            ...buildImageList(
                widget.data.location?[locale]['images'].cast<String>()),
          const SizedBox(height: 24),
          ...buildTextList(widget.data.location?[locale]['desc'].cast<String>(),
              getTextStyle(AppTypo.body16B, AppColors.grey900)),
        ];
      case RewardType.sizeGuide:
        return widget.data.sizeGuide?[locale]?.map<Widget>((value) {
              return Column(
                children: [
                  ...buildSizeGuideImageList(value['image'].cast<String>()),
                  const SizedBox(height: 24),
                  ...buildTextList(value['desc'].cast<String>().sublist(0, 1),
                      getTextStyle(AppTypo.body16B, AppColors.grey900)),
                  ...buildTextList(value['desc'].cast<String>().sublist(1),
                      getTextStyle(AppTypo.body16R, AppColors.grey900)),
                  const SizedBox(height: 24),
                ],
              );
            }).toList() ??
            [];
      default:
        return [];
    }
  }

  List<Widget> buildImageList(List<String>? images,
      [BoxDecoration? decoration]) {
    if (images == null) return [];
    return images.asMap().entries.map((entry) {
      int i = entry.key;
      String image = entry.value;
      return Column(
        children: [
          Container(
            decoration: decoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                alignment: Alignment.topCenter,
                width: 300,
                height: 300,
                child: PicnicCachedNetworkImage(
                  imageUrl: image,
                  width: 400,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (i != images.length - 1) const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  List<Widget> buildSizeGuideImageList(List<String>? images) {
    if (images == null) return [];
    return images.asMap().entries.map((entry) {
      int i = entry.key;
      String image = entry.value;
      return Column(
        children: [
          SizedBox(
            child: PicnicCachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
            ),
          ),
          if (i != images.length - 1) const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  List<Widget> buildTextList(List<String>? texts, [TextStyle? style]) {
    if (texts == null) return [];
    return texts
        .map((text) => Text(
              text,
              style: style ?? getTextStyle(AppTypo.body16R, AppColors.grey900),
              textAlign: TextAlign.center,
            ))
        .toList();
  }

  List<Widget> buildTextAddress(List<String>? texts, [TextStyle? style]) {
    if (texts == null) return [];
    return texts
        .map((text) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Text(
                    '· $text',
                    style: style ??
                        getTextStyle(AppTypo.body16R, AppColors.grey900),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () => copyToClipboard(context, text),
                  child: Text(
                    'COPY',
                    style: getTextStyle(AppTypo.body16B, AppColors.primary500),
                  ),
                ),
              ],
            ))
        .toList();
  }
}
