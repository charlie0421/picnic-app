import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/presentation/widgets/celeb_list_item.dart';
import 'package:picnic_app/presentation/widgets/error.dart';
import 'package:picnic_app/presentation/widgets/no_bookmark_celeb.dart';
import 'package:picnic_app/presentation/widgets/search_list.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/presentation/providers/celeb_list_provider.dart';
import 'package:picnic_app/presentation/providers/celeb_search_provider.dart';
import 'package:picnic_app/core/utils/ui.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  @override
  Widget build(BuildContext context) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final asyncMyCelebListState = ref.watch(asyncMyCelebListProvider);

    return asyncCelebListState.when(
        data: (data) {
          final myCelebList = asyncMyCelebListState.value;

          final celebList = data?.where((element) {
            return myCelebList?.map((e) => e.id).contains(element.id) == false;
          }).toList();
          return _dataView(myCelebList, celebList);
        },
        error: (error, stackTrace) => buildErrorView(context,
            error: asyncCelebListState.error, stackTrace: stackTrace),
        loading: () => buildLoadingOverlay());
  }

  _dataView(myCelebList, celebList) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36.0),
      child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).lable_my_celeb,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (myCelebList.length == 0)
            const NoBookmarkCeleb()
          else
            ...myCelebList.map((item) {
              return CelebListItem(
                item: item,
                type: 'my',
                moveHome: true,
              );
            }),
          const SizedBox(height: 16),
          Text(S.of(context).label_celeb_recommend,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (BuildContext context) => const SearchList());
              ref.read(asyncCelebSearchProvider.notifier).reset();
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFE6FBEE),
                border: Border.all(color: const Color(0xFFB7B7B7)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8.cw),
                  child: SvgPicture.asset(
                    'assets/landing/search_icon.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...celebList?.map((item) {
            return CelebListItem(
              item: item,
              type: 'find',
            );
          }),
        ],
      )),
    );
  }
}
