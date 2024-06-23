import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/providers/celeb_search_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

import '../constants.dart';

class CelebListItem extends ConsumerWidget {
  final CelebModel item;
  final String type;
  bool? showBookmark;
  bool? enableBookmark;
  bool? moveHome;
  VoidCallback? onTap;

  CelebListItem({
    super.key,
    this.showBookmark = true,
    this.enableBookmark = true,
    this.moveHome = false,
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

    return InkWell(
      onTap: () async {
        selectedCelebNotifier.setSelectedCeleb(item);
        logger.i('selectedCeleb: ${item.name_ko}');
        onTap?.call();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnail ?? '',
                    width: 60,
                    height: 60,
                    placeholder: (context, url) => buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 16),
                Text(item.name_ko,
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            showBookmark != null && !showBookmark!
                ? Container()
                : type == 'my'
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: enableBookmark != null && enableBookmark!
                            ? () async {
                                await asyncCelebListNotifier
                                    .removeBookmark(item);
                                asyncCelebSearchNotifier.repeatSearch();
                                if (getBookmarkCount(ref.read(
                                        asyncCelebListProvider
                                            as ProviderListenable<
                                                AsyncValue<
                                                    List<CelebModel>>?>))! <=
                                    0) {}
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
                                if (getBookmarkCount(asyncCelebListState
                                        as AsyncValue<List<CelebModel>>?)! >=
                                    5) {
                                  showOverlayToast(
                                      context,
                                      Text(S.of(context).toast_max_5_celeb,
                                          style: getTextStyle(AppTypo.BODY16M,
                                              AppColors.Grey900)));

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
      ),
    );
  }

  int? getBookmarkCount(AsyncValue<List<CelebModel>>? celebList) {
    return celebList?.value
        ?.where((element) =>
            element.users!.where((element) => element.id == 2).isNotEmpty)
        .length;
  }
}
