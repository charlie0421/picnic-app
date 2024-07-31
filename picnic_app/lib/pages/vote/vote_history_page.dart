import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/custom_dropdown_button.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote_pick.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/number.dart';

class VoteHistoryPage extends ConsumerStatefulWidget {
  final String pageName = 'label_mypage_vote_history';

  const VoteHistoryPage({super.key});

  @override
  ConsumerState createState() => _VoteHistoryPageState();
}

class _VoteHistoryPageState extends ConsumerState<VoteHistoryPage> {
  final PagingController<int, VotePickModel> _pagingController =
      PagingController(firstPageKey: 1);
  String _sortOrder = 'DESC';

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', _sortOrder).then((newItems) {
        logger.i(newItems.meta);
        final isLastPage = newItems.meta.itemCount < 10;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems.items);
        } else {
          final nextPageKey = newItems.meta.currentPage + 1;
          _pagingController.appendPage(newItems.items, nextPageKey);
        }
      });
    });
  }

  _fetch(int page, int limit, String sort, String order) async {
    final response = await supabase
        .from('vote_pick')
        .select('*, vote(*), vote_item(*, artist(*, artist_group(*)))')
        .order(
          sort,
          ascending: order == 'ASC',
        )
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final meta = {
      'totalItems': response.count,
      'currentPage': page,
      'itemCount': response.data.length,
      'itemsPerPage': limit,
      'totalPages': response.count / limit,
    };

    return VotePickListModel.fromJson({'items': response.data, 'meta': meta});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.centerRight,
          child: CustomDropdown(
            key: const Key('sortOrderDropdown'),
            value: _sortOrder,
            onChanged: (value) {
              setState(() {
                _sortOrder = value.toString();
                _pagingController.refresh();
              });
            },
            items: [
              CustomDropdownMenuItem(
                  value: 'DESC', text: S.of(context).label_dropdown_recent),
              CustomDropdownMenuItem(
                  value: 'ASC', text: S.of(context).label_dropdown_oldest),
            ],
          ),
        ),
        Expanded(
          child: PagedListView(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<VotePickModel>(
                itemBuilder: (context, item, index) {
                  return Container(
                    height: 107.w,
                    padding: EdgeInsets.all(16.w),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.Grey300, width: 1))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy.MM.dd HH:mm:ss')
                                  .format(item.created_at),
                              style: getTextStyle(
                                  AppTypo.CAPTION12R, AppColors.Grey900),
                            ),
                            Text(
                              S.of(context).text_vote_complete,
                              style: getTextStyle(
                                  AppTypo.CAPTION12M, AppColors.Grey900),
                            ),
                          ],
                        ),
                        Text(
                            '${formatNumberWithComma(item.amount)} ${S.of(context).text_star_candy}',
                            style: getTextStyle(
                                AppTypo.TITLE18B, AppColors.Grey900)),
                        RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: getLocaleTextFromJson(item.vote.title),
                              style: getTextStyle(
                                  AppTypo.BODY14M, AppColors.Grey900)),
                          TextSpan(
                              text:
                                  '${getLocaleTextFromJson(item.vote_item.artist.name)}_${getLocaleTextFromJson(item.vote_item.artist.artist_group.name)}',
                              style: getTextStyle(
                                  AppTypo.BODY14M, AppColors.Grey900)),
                        ])),
                      ],
                    ),
                  );
                },
              )),
        ),
      ],
    );
  }
}
