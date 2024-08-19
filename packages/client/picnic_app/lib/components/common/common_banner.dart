import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/custom_pagination.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/banner_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:shimmer/shimmer.dart';

class CommonBanner extends ConsumerStatefulWidget {
  const CommonBanner(this.location, this.height, {super.key});

  final String location;
  final double? height;

  @override
  ConsumerState<CommonBanner> createState() => _CommonBannerState();
}

class _CommonBannerState extends ConsumerState<CommonBanner> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final asyncBannerListState =
        ref.watch(asyncBannerListProvider(location: widget.location));
    final width =
        kIsWeb ? webDesignSize.width : MediaQuery.of(context).size.width;
    return asyncBannerListState.when(
      data: (data) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            height: widget.height ?? width / 2,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                String title = getLocaleTextFromJson(data[index].title);
                return Stack(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      width: width,
                      child: PicnicCachedNetworkImage(
                          imageUrl:
                              getLocaleTextFromJson(data[index].image) ?? '',
                          width: width.toInt(),
                          height: (width / 2).toInt(),
                          fit: BoxFit.fitWidth),
                    ),
                    if (title.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8.w),
                          color: Colors.black.withOpacity(0.5),
                          child: Text(
                            title,
                            style: getTextStyle(AppTypo.body14R, Colors.white)
                                .copyWith(overflow: TextOverflow.ellipsis),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
              itemCount: data.length,
              onIndexChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              autoplay: data.length > 1,
            ),
          ),
          if (data.length > 1)
            SizedBox(
              height: 20,
              child: CustomPagination(
                itemCount: data.length,
                activeIndex: _currentIndex,
              ),
            ),
        ],
      ),
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Column(
          children: [
            Container(
              width: width,
              height: width / 2,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8.w,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) =>
          ErrorView(context, error: error.toString(), stackTrace: stackTrace),
    );
  }
}
