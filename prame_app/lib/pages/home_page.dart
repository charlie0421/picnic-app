import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/providers/celeb_banner_list_provider.dart';
import 'package:prame_app/providers/selected_celeb_provider.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCelebState = ref.watch(selectedCelebProvider);
    final celebBannerListState = ref.watch(
        asyncCelebBannerListProvider(celebId: selectedCelebState?.id ?? 1));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.Gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            height: 80,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(Intl.message('text_ads_random'),
                    style: getTextStyle(AppTypo.UI18M, AppColors.Gray900)),
                Text('01:00:00',
                    style: getTextStyle(AppTypo.UI18M, AppColors.Gray900)),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          celebBannerListState.when(
            data: (data) {
              return SizedBox(
                height: 236,
                width: MediaQuery.of(context).size.width - 32,
                child: Swiper(
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: data.items[index].thumbnail,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  itemCount: data.items.length,
                  pagination: const SwiperPagination(),
                  autoplay: true,
                ),
              );
            },
            loading: () => buildLoadingOverlay(),
            error: (error, stackTrace) => ErrorView(
              context,
              retryFunction: () {
                ref.refresh(asyncCelebBannerListProvider(
                    celebId: selectedCelebState?.id ?? 1));
              },
              error: error,
              stackTrace: stackTrace,
            ),
          ),
          const SizedBox(height: 20),
        ],
      )),
    );
  }
}
