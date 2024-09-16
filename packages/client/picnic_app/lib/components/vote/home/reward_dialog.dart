import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/util.dart';

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
      return Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  buildTopSection(),
                  const SizedBox(height: 67),
                  buildSection(RewardType.overview),
                  buildSection(RewardType.location),
                  buildSection(RewardType.size_guide),
                  const SizedBox(height: 56),
                ],
              ),
            ),
            Positioned(
              top: 40.cw,
              right: 15.cw,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  foregroundColor: AppColors.grey500,
                  child: const Icon(
                    Icons.close,
                    size: 24,
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
        SizedBox(
          width: getPlatformScreenSize(context).width,
          height: getPlatformScreenSize(context).width,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.7, 1],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: PicnicCachedNetworkImage(
              imageUrl: widget.data.thumbnail ?? '',
              width: 400,
              height: 400,
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
              margin: EdgeInsets.only(left: 16.cw, right: 16.cw, top: 12),
              padding: EdgeInsets.only(
                      left: 24.cw, right: 24.cw, top: 53, bottom: 41)
                  .r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.primary500, width: 1.5.r),
              ),
              child: Column(
                children: buildSectionContent(type),
              ),
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
      case RewardType.size_guide:
        final locale = Intl.getCurrentLocale();

        return widget.data.size_guide != null &&
                widget.data.size_guide?[locale] != null
            ? widget.data.size_guide![locale].map<Widget>((value) {
                // logger.i(value);
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
                  child: Container(
                    alignment: Alignment.topCenter,
                    width: 300,
                    height: 300,
                    child: PicnicCachedNetworkImage(
                      imageUrl: images[i],
                      width: 400,
                      height: 400,
                      fit: BoxFit.cover,
                    ),
                  ),
                )),
            if (i != images.length - 1) const SizedBox(height: 12),
            // 마지막 요소가 아닐 때만 추가
          ],
        ),
      );
    }
    return imageWidgets;
  }

  List<Widget> buildSizeGuideImageList(
    List<String>? images,
  ) {
    if (images == null) return [];
    List<Widget> imageWidgets = [];
    for (int i = 0; i < images.length; i++) {
      imageWidgets.add(
        Column(
          children: [
            SizedBox(
              child: PicnicCachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
              ),
            ),
            if (i != images.length - 1) const SizedBox(height: 12),
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
              style: style ?? getTextStyle(AppTypo.body16R, AppColors.grey900),
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
                        getTextStyle(AppTypo.body16R, AppColors.grey900),
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
                          getTextStyle(AppTypo.body16B, AppColors.primary500),
                    ),
                  ),
                ),
              ],
            ))
        .toList();
  }
}
