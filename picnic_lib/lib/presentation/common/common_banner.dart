import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

class CommonBanner extends ConsumerStatefulWidget {
  const CommonBanner(this.location, this.aspectRatio, {super.key});

  final String location;
  final double aspectRatio;

  @override
  ConsumerState<CommonBanner> createState() => _CommonBannerState();
}

class _CommonBannerState extends ConsumerState<CommonBanner> {
  int _currentIndex = 0;
  SwiperController? _swiperController;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _swiperController?.dispose();
    super.dispose();
  }

  void _startAutoplay(List<BannerModel> banners) {
    _autoplayTimer?.cancel();
    if (banners.length > 1) {
      _autoplayTimer = Timer(
        Duration(milliseconds: banners[_currentIndex].duration),
        () {
          if (mounted) {
            final nextIndex = (_currentIndex + 1) % banners.length;
            _swiperController?.move(nextIndex);
          }
        },
      );
    }
  }

  Widget _buildBannerItem(BannerModel item) {
    String title = getLocaleTextFromJson(item.title);
    String imageUrl = getLocaleTextFromJson(item.image);
    imageUrl.toLowerCase().endsWith('.gif');

    return GestureDetector(
      onTap: () {
        if (item.link != null) {
          AppInitializer.handleDeepLink(ref, item.link!);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // key를 추가하여 위젯을 강제로 리빌드
          PicnicCachedNetworkImage(
            key: ValueKey('${item.id}_$_currentIndex'),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
          if (title.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8.w),
                color: Colors.black.withValues(alpha: 0.5),
                child: Text(
                  title,
                  style: getTextStyle(AppTypo.body14R, Colors.white)
                      .copyWith(overflow: TextOverflow.ellipsis),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncBannerListState =
        ref.watch(asyncBannerListProvider(location: widget.location));
    final width = ref.watch(globalMediaQueryProvider).size.width;

    return asyncBannerListState.when(
      data: (List<BannerModel> data) {
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        // 데이터가 로드되면 자동재생 시작
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoplay(data);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: data.length == 1
                  ? _buildBannerItem(data[0])
                  : Swiper(
                      controller: _swiperController,
                      itemBuilder: (BuildContext context, int index) =>
                          _buildBannerItem(data[index]),
                      itemCount: data.length,
                      onIndexChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _startAutoplay(data);
                      },
                      autoplay: false,
                      duration: 300,
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
        );
      },
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Container(
                width: width,
                color: Colors.white,
              ),
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
      error: (error, stackTrace) => buildErrorView(context,
          error: error.toString(), stackTrace: stackTrace),
    );
  }
}
