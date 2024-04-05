import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
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
    final celebSearchState = ref.watch(celebSearchProvider);
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
                logger.i(value);
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
                itemCount: celebSearchState.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 32, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                                'assets/mockup/landing/${celebSearchState[index].image}',
                                width: 60,
                                height: 60),
                            const SizedBox(width: 16),
                            Text(celebSearchState[index].name,
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            showOverlayToast(
                                context,
                                Text(Intl.message('toast_max_5_celeb'),
                                    style: getTextStyle(
                                        AppTypo.UI16M, AppColors.Gray900)));
                          },
                          child: SvgPicture.asset(
                            'assets/landing/bookmark_add.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFFC4C4C4), BlendMode.srcIn),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
