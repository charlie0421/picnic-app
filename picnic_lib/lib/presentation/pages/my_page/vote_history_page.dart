import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/custom_dropdown_button.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteHistoryPage extends ConsumerStatefulWidget {
  const VoteHistoryPage({super.key});

  @override
  ConsumerState createState() => _VoteHistoryPageState();
}

class _VoteHistoryPageState extends ConsumerState<VoteHistoryPage> {
  late final PagingController<int, VotePickModel> _pagingController;
  String _sortOrder = 'DESC';
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, VotePickModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetch,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
          pageTitle: AppLocalizations.of(context).label_mypage_vote_history);
    });
  }

  Future<List<VotePickModel>> _fetch(int pageKey) async {
    try {
      final response = await supabase
          .from('vote_pick')
          .select(
              'id,amount,star_candy_usage,star_candy_bonus_usage,created_at,updated_at,vote(id,title,vote_category,main_image,wait_image,result_image,vote_content,created_at,visible_at,stop_at,start_at,is_partnership,partner),vote_item(id,vote_total,star_candy_total,star_candy_bonus_total,vote_id,artist(id,name,yy,mm,dd,birth_date,gender,image,created_at,updated_at,deleted_at,artist_group(id,name,image,created_at,updated_at,deleted_at)),artist_group(id,name,image,created_at,updated_at,deleted_at))')
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('id', ascending: _sortOrder == 'ASC')
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1)
          .limit(_pageSize);

      final now = DateTime.now().toUtc();
      
      // Add computed fields to vote data before parsing
      for (var item in response as List) {
        if (item['vote'] != null) {
          final voteData = item['vote'] as Map<String, dynamic>;
          if (voteData['stop_at'] != null && voteData['start_at'] != null) {
            voteData['is_ended'] = now.isAfter(DateTime.parse(voteData['stop_at']));
            voteData['is_upcoming'] = now.isBefore(DateTime.parse(voteData['start_at']));
          } else {
            voteData['is_ended'] = false;
            voteData['is_upcoming'] = false;
          }
        }
      }

      final items = (response as List)
          .map((item) => VotePickModel.fromJson(item))
          .toList();

      return items;
    } catch (error) {
      logger.e(error);
      rethrow;
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
                value: 'DESC',
                text: AppLocalizations.of(context).label_dropdown_recent,
              ),
              CustomDropdownMenuItem(
                value: 'ASC',
                text: AppLocalizations.of(context).label_dropdown_oldest,
              ),
            ],
          ),
        ),
        Expanded(
          child: PagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) =>
                PagedListView<int, VotePickModel>(
              state: _pagingController.value,
              fetchNextPage: _pagingController.fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<VotePickModel>(
                noItemsFoundIndicatorBuilder: (context) =>
                    const NoItemContainer(),
                itemBuilder: (context, item, index) => Container(
                  height: 107,
                  padding: EdgeInsets.all(16.w),
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
                            AppLocalizations.of(context).text_vote_complete,
                            style: getTextStyle(
                              AppTypo.caption12M,
                              AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${formatNumberWithComma(item.amount)} ${AppLocalizations.of(context).text_star_candy}',
                        style:
                            getTextStyle(AppTypo.title18B, AppColors.grey900),
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
                            (item.voteItem.artist?.id ?? 0) != 0
                                ? TextSpan(
                                    text:
                                        '${getLocaleTextFromJson(item.voteItem.artist?.name ?? {})}_${getLocaleTextFromJson(item.voteItem.artist?.artistGroup?.name ?? {})}',
                                    style: getTextStyle(
                                      AppTypo.caption12R,
                                      AppColors.grey900,
                                    ),
                                  )
                                : TextSpan(
                                    text: getLocaleTextFromJson(
                                      item.voteItem.artistGroup?.name ?? {},
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
        ),
      ],
    );
  }
}
