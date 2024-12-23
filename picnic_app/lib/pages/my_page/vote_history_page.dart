import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/custom_dropdown_button.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote_pick.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/number.dart';
import 'package:picnic_app/util/ui.dart';

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
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: S.of(context).label_mypage_vote_history);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await supabase
          .from('vote_pick')
          .select(
              'id,amount,created_at,vote(id,title),vote_item(id,vote_id,artist(id,name,artist_group(id,name)),artist_group(id,name))')
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('id', ascending: _sortOrder == 'ASC')
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1)
          .limit(_pageSize);

      final items = (response as List)
          .map((item) => VotePickModel.fromJson(item))
          .toList();

      final isLastPage = items.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(items);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(items, nextPageKey);
      }
    } catch (error) {
      logger.e(error);
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.cw),
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
                value: 'DESC',
                text: S.of(context).label_dropdown_recent,
              ),
              CustomDropdownMenuItem(
                value: 'ASC',
                text: S.of(context).label_dropdown_oldest,
              ),
            ],
          ),
        ),
        Expanded(
          child: PagedListView<int, VotePickModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<VotePickModel>(
              itemBuilder: (context, item, index) => Container(
                height: 107,
                padding: EdgeInsets.all(16.cw),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey300, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm:ss')
                              .format(item.createdAt!),
                          style: getTextStyle(
                            AppTypo.caption12R,
                            AppColors.grey900,
                          ),
                        ),
                        Text(
                          S.of(context).text_vote_complete,
                          style: getTextStyle(
                            AppTypo.caption12M,
                            AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatNumberWithComma(item.amount)} ${S.of(context).text_star_candy}',
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: getLocaleTextFromJson(item.vote.title),
                            style: getTextStyle(
                              AppTypo.body14M,
                              AppColors.grey900,
                            ),
                          ),
                          TextSpan(
                            text: ' ',
                            style: getTextStyle(
                              AppTypo.body14M,
                              AppColors.grey900,
                            ),
                          ),
                          item.voteItem.artist.id != 0
                              ? TextSpan(
                                  text:
                                      '${getLocaleTextFromJson(item.voteItem.artist.name)}_${getLocaleTextFromJson(item.voteItem.artist.artist_group!.name)}',
                                  style: getTextStyle(
                                    AppTypo.caption12R,
                                    AppColors.grey900,
                                  ),
                                )
                              : TextSpan(
                                  text: getLocaleTextFromJson(
                                    item.voteItem.artistGroup.name,
                                  ),
                                  style: getTextStyle(
                                    AppTypo.caption12R,
                                    AppColors.grey900,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
