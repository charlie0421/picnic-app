import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/providers/celeb_search_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class CelebListItem extends ConsumerWidget {
  final CelebModel item;
  final String type;
  final bool showBookmark;
  final bool enableBookmark;
  final bool moveHome;
  final VoidCallback? onTap;

  const CelebListItem({
    super.key,
    required this.item,
    required this.type,
    this.showBookmark = true,
    this.enableBookmark = true,
    this.moveHome = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final asyncCelebListNotifier = ref.read(asyncCelebListProvider.notifier);
    final asyncCelebSearchNotifier =
        ref.read(asyncCelebSearchProvider.notifier);
    final selectedCelebNotifier = ref.read(selectedCelebProvider.notifier);

    return InkWell(
      onTap: () {
        selectedCelebNotifier.setSelectedCeleb(item);
        logger.i('selectedCeleb: ${item.nameKo}');
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
                ProfileImageContainer(
                  avatarUrl: item.thumbnail,
                  borderRadius: 20,
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 16),
                Text(item.nameKo,
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            if (showBookmark)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enableBookmark
                    ? () async {
                        if (type == 'my') {
                          await asyncCelebListNotifier.removeBookmark(item);
                        } else {
                          if (await getBookmarkCount(asyncCelebListState) >=
                              5) {
                            showOverlayToast(
                              context,
                              Text(
                                S.of(context).toast_max_five_celeb,
                                style: getTextStyle(
                                    AppTypo.body16M, AppColors.grey900),
                              ),
                            );
                            return;
                          }
                          await asyncCelebListNotifier.addBookmark(item);
                        }
                        asyncCelebSearchNotifier.repeatSearch();
                      }
                    : null,
                child: SvgPicture.asset(
                  type == 'my'
                      ? 'assets/landing/bookmark_added.svg'
                      : 'assets/landing/bookmark_add.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Color(type == 'my' ? 0xFF08C97E : 0xFFC4C4C4),
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<int> getBookmarkCount(AsyncValue<List<CelebModel>?> celebList) async {
    logger.i(celebList.value);

    final response = await supabase
        .from('celeb_bookmark_user')
        .select()
        .eq('celeb_id', item.id)
        .eq('user_id', supabase.auth.currentUser!.id)
        .count();

    return response.count;
  }
}
