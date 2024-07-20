import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteList extends StatefulWidget {
  final VoteStatus status;
  final VoteCategory category;

  const VoteList(this.status, this.category, {super.key});

  @override
  State<VoteList> createState() => _VoteListState();
}

class _VoteListState extends State<VoteList> {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', "DESC", status: widget.status).then((newItems) {
        final isLastPage =
            newItems.meta.currentPage == newItems.meta.totalPages;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems.items);
        } else {
          final nextPageKey = newItems.meta.currentPage + 1;
          _pagingController.appendPage(newItems.items, nextPageKey);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, VoteModel>(
      shrinkWrap: true,
      pagingController: _pagingController,
      scrollDirection: Axis.vertical,
      builderDelegate: PagedChildBuilderDelegate<VoteModel>(
          firstPageErrorIndicatorBuilder: (context) {
            return ErrorView(context,
                error: _pagingController.error.toString(),
                retryFunction: () => _pagingController.refresh(),
                stackTrace: _pagingController.error.stackTrace);
          },
          firstPageProgressIndicatorBuilder: (context) {
            return buildLoadingOverlay();
          },
          noItemsFoundIndicatorBuilder: (context) {
            if (widget.status == VoteStatus.active) {
              return Center(
                  child: Text(
                S.of(context).message_noitem_vote_active,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey500),
              ));
            } else if (widget.status == VoteStatus.end) {
              return Center(
                  child: Text(
                S.of(context).message_noitem_vote_end,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey500),
              ));
            } else if (widget.status == VoteStatus.upcoming) {
              return Center(
                child: Text(
                  S.of(context).message_noitem_vote_upcoming,
                  style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey500),
                ),
              );
            }
            return Container();
          },
          itemBuilder: (context, item, index) => Column(
                children: [
                  VoteInfoCard(
                    context: context,
                    vote: item,
                    status: widget.status,
                  ),
                  Divider(
                    height: 1.h,
                    color: AppColors.Grey300,
                  ),
                ],
              )),
    );
  }

  Future<VoteListModel> _fetch(int page, int limit, String sort, String order,
      {required VoteStatus status}) async {
    PostgrestResponse<PostgrestList> response;

    logger.i(status);

    if (status == VoteStatus.active) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .lt('start_at', 'now()')
          .gt('stop_at', 'now()')
          .order('id', ascending: false)
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();

      logger.i(response.data);
    } else if (status == VoteStatus.end) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .lt('stop_at', 'now()')
          .order(
            sort,
            ascending: order == 'ASC',
          )
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else if (status == VoteStatus.upcoming) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .lt('visible_at', 'now()')
          .gt('start_at', 'now()')
          .order(
            sort,
            ascending: order == 'ASC',
          )
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .order(
            sort,
            ascending: order == 'ASC',
          )
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    }

    final meta = {
      'totalItems': response.count,
      'currentPage': page,
      'itemCount': response.data.length,
      'itemsPerPage': limit,
      'totalPages': (response.count / limit).ceil(),
    };

    return VoteListModel.fromJson({'items': response.data, 'meta': meta});
  }
}
