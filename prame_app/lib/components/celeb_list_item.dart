import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/models/celeb.dart';
import 'package:prame_app/providers/celeb_list_provider.dart';
import 'package:prame_app/providers/celeb_search_provider.dart';
import 'package:prame_app/providers/selected_celeb_provider.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

import '../constants.dart';

class CelebListItem extends ConsumerWidget {
  final CelebModel item;
  final String type;
  bool? showBookmark;
  bool? enableBookmark;

  CelebListItem({
    super.key,
    this.showBookmark = true,
    this.enableBookmark = true,
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final asyncCelebListNotifier = ref.read(asyncCelebListProvider.notifier);
    final asyncCelebSearchNotifier =
        ref.read(asyncCelebSearchProvider.notifier);
    final selectedCelebNotifier = ref.read(selectedCelebProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: item.thumbnail,
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 16),
              Text(item.nameKo, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          showBookmark != null && !showBookmark!
              ? Container()
              : type == 'my'
                  ? GestureDetector(
                      onTap: enableBookmark != null && enableBookmark!
                          ? () async {
                              await asyncCelebListNotifier.removeBookmark(item);
                              asyncCelebSearchNotifier.repeatSearch();
                              logger.i(
                                  'getBookmarkCount(asyncCelebListState): ${getBookmarkCount(ref.read(asyncCelebListProvider))}');
                              if (getBookmarkCount(
                                      ref.read(asyncCelebListProvider))! <=
                                  0) {
                                logger.i(
                                    'selectedCelebNotifier.setSelectedCeleb(null)');
                                selectedCelebNotifier.setSelectedCeleb(null);
                              }
                            }
                          : () {},
                      child: SvgPicture.asset(
                        'assets/landing/bookmark_added.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                            Color(type == 'my' ? 0xFF08C97E : 0xFFC4C4C4),
                            BlendMode.srcIn),
                      ),
                    )
                  : InkWell(
                      onTap: enableBookmark != null && enableBookmark!
                          ? () async {
                              if (getBookmarkCount(asyncCelebListState)! >= 5) {
                                showOverlayToast(
                                    context,
                                    Text(Intl.message('toast_max_5_celeb'),
                                        style: getTextStyle(
                                            AppTypo.UI16M, AppColors.Gray900)));

                                return;
                              }
                              await asyncCelebListNotifier.addBookmark(item);
                              asyncCelebSearchNotifier.repeatSearch();
                            }
                          : () {},
                      child: SvgPicture.asset(
                        'assets/landing/bookmark_add.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                            Color(type == 'my' ? 0xFF08C97E : 0xFFC4C4C4),
                            BlendMode.srcIn),
                      ),
                    ),
        ],
      ),
    );
  }

  int? getBookmarkCount(AsyncValue<CelebListModel> celebList) {
    return celebList.value?.items
        .where((element) =>
            element.users!.where((element) => element.id == 2).isNotEmpty)
        .length;
  }
}
