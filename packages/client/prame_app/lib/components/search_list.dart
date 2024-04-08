import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/celeb_list_item.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/models/celeb.dart';
import 'package:prame_app/providers/celeb_search_provider.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                hintText: Intl.message('text_hint_search'),
                hintStyle: getTextStyle(AppTypo.UI14B, AppColors.Gray300),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/textclear.svg'),
                  onPressed: () {
                    _textEditingController.clear();
                  },
                ),
              ),
              onChanged: (value) {
                if (value == null || value.isNotEmpty) {
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

  Widget _buildSearchList(CelebListModel data) {
    return Expanded(
      child: ListView.separated(
          itemCount: data.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return CelebListItem(
                item: data.items[index],
                type: data.items[index].users!.isEmpty ? 'find' : 'my');
          }),
    );
  }
}
