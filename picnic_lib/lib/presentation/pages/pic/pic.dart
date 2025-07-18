import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/celeb_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class PicPage extends ConsumerStatefulWidget {
  const PicPage({super.key});

  @override
  createState() => _PicPageState();
}

class _PicPageState extends ConsumerState<PicPage> {
  int selectedPicIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            padding: const EdgeInsets.only(
              top: 8,
            ),
            child: _buildSelectArtist()),
        Flexible(
          child: Container(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 52,
            ),
            child: AspectRatio(
              aspectRatio: 5.5 / 8.5,
              child: CardSwiper(
                  numberOfCardsDisplayed: 3,
                  backCardOffset: const Offset(-30, 40),
                  padding: const EdgeInsets.all(0),
                  cardsCount: 3,
                  cardBuilder:
                      (context, index, percentThresholdX, percentThresholdY) =>
                          _buildPicCard(index)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPicCard(int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPicIndex = index;
        });
        _showCameraView();
      },
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.secondary500,
            border: Border.all(
              color: AppColors.primary500,
              width: 3.w,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                package: 'picnic_lib',
                'assets/mockup/pic/che${index + 1}.png',
              ),
            ],
          )),
    );
  }

  Widget _buildSelectArtist() {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);

    return asyncCelebListState.when(
      data: (data) {
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data?.length ?? 0,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) return SizedBox(width: 16.w);
              return SizedBox(
                width: 60.w,
                height: 60,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: PicnicCachedNetworkImage(
                        imageUrl: data?[index - 1].thumbnail ?? '',
                        width: 60.w,
                        height: 60,
                        fit: BoxFit.cover,
                        priority: ImagePriority.high, // 아티스트 이미지는 높은 우선순위
                        borderRadius: BorderRadius.circular(70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(data?[index - 1].nameKo ?? '',
                        style: getTextStyle(AppTypo.body16B, AppColors.grey900))
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stackTrace) => const Text('error'),
    );
  }

  void _showCameraView() {
    Navigator.pushNamed(context, '/pic-camera');
    // ref.read(navigationInfoProvider.notifier).setCurrentPage(
    //     PicCameraViewPage(),
    //     showTopMenu: false,
    //     showBottomNavigation: false);
    // showModalBottomSheet(
    //     context: context,
    //     useSafeArea: true,
    //     isScrollControlled: true,
    //     useRootNavigator: true,
    //     showDragHandle: false,
    //     builder: (BuildContext context) {
    //       return PicCameraViewPage();
    //     });
  }
}
