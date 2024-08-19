import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/celeb_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/providers/celeb_search_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class SearchList extends ConsumerStatefulWidget {
  const SearchList({super.key});

  @override
  ConsumerState<SearchList> createState() => _SearchListState();
}

class _SearchListState extends ConsumerState<SearchList> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final asyncCelebSearchState = ref.watch(asyncCelebSearchProvider);
    final asyncCelebSearchNotifier =
        ref.read(asyncCelebSearchProvider.notifier);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFE6FBEE),
              border: Border.all(color: const Color(0xFFB7B7B7)),
            ),
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: S.of(context).text_hint_search,
                hintStyle: getTextStyle(AppTypo.body14B, AppColors.grey300),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                suffixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/textclear.svg'),
                  onPressed: () {
                    _textEditingController.clear();
                  },
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  asyncCelebSearchNotifier.searchCeleb(value);
                  return;
                } else {
                  asyncCelebSearchNotifier.reset();
                }
              },
            ),
          ),
          asyncCelebSearchState.when(
            data: (data) {
              if (data == null || data.isEmpty) {
                return const SizedBox();
              }
              return _buildSearchList(data);
            },
            loading: () => buildLoadingOverlay(),
            error: (error, stackTrace) =>
                ErrorView(context, error: error, stackTrace: stackTrace),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchList(List<CelebModel> data) {
    return Expanded(
      child: ListView.separated(
          itemCount: data.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return CelebListItem(
                item: data[index],
                type: data[index].users!.isEmpty ? 'find' : 'my');
          }),
    );
  }
}
