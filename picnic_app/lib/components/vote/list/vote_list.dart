import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
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
      _fetch(pageKey, 10, status: widget.status).then((newItems) {
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
  void dispose() {
    _pagingController.dispose();
    super.dispose();
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
              return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    S.of(context).message_noitem_vote_active,
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey500),
                  ));
            } else if (widget.status == VoteStatus.end) {
              return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    S.of(context).message_noitem_vote_end,
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey500),
                  ));
            } else if (widget.status == VoteStatus.upcoming) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                child: Text(
                  S.of(context).message_noitem_vote_upcoming,
                  style: getTextStyle(AppTypo.caption12M, AppColors.grey500),
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
                  const Divider(
                    height: 1,
                    color: AppColors.grey300,
                  ),
                ],
              )),
    );
  }

  Future<VoteListModel> _fetch(int page, int limit,
      {required VoteStatus status}) async {
    PostgrestResponse<PostgrestList> response;

    if (status == VoteStatus.active) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .filter('deleted_at', 'is', null)
          .lt('start_at', 'now()')
          .gt('stop_at', 'now()')
          .order('start_at', ascending: true)
          .order('order', ascending: true)
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else if (status == VoteStatus.end) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .filter('deleted_at', 'is', null)
          .lt('stop_at', 'now()')
          .order('stop_at', ascending: false)
          .order('order', ascending: true)
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else if (status == VoteStatus.upcoming) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
          .filter('deleted_at', 'is', null)
          .lt('visible_at', 'now()')
          .gt('start_at', 'now()')
          .order('start_at', ascending: true)
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, artist(*, artist_group(*)))')
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
