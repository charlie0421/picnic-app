import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/celeb_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/no_bookmark_celeb.dart';
import 'package:picnic_app/components/search_list.dart';
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/providers/celeb_search_provider.dart';
import 'package:picnic_app/util.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  @override
  Widget build(BuildContext context) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    int userId = 2;

    return asyncCelebListState.when(
        data: (data) {
          final myCelebList = data
              ?.where((element) => element.users!
                  .where((element) => element.id == userId)
                  .isNotEmpty)
              .toList();
          final celebList = data
              ?.where((element) => element.users!
                  .where((element) => element.id == userId)
                  .isEmpty)
              .toList();
          return _dataView(myCelebList, celebList);
        },
        error: (error, stackTrace) => ErrorView(context,
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
          Text(Intl.message('lable_my_celeb'),
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
          Text(Intl.message('label_celeb_recommend'),
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
                  padding: const EdgeInsets.only(right: 8),
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
          ...celebList.map((item) {
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
