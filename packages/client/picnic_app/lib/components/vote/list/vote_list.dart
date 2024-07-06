import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
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
            return const Center(child: Text('No Items Found'));
          },
          itemBuilder: (context, item, index) =>
              VoteInfoCard(context: context, vote: item)),
    );
  }

  Future<VoteListModel> _fetch(int page, int limit, String sort, String order,
      {required VoteStatus status}) async {
    PostgrestResponse<PostgrestList> response;

    if (status == VoteStatus.active) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
          .lt('start_at', 'now()')
          .gt('stop_at', 'now()')
          .order('id', ascending: false)
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    } else if (status == VoteStatus.end) {
      response = await supabase
          .from('vote')
          .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
          .lt('stop_at', 'now()')
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
          .select('*, vote_item(*, mystar_member(*))')
          .order(
            sort,
            ascending: order == 'ASC',
          )
          .order('vote_total', ascending: false, referencedTable: 'vote_item')
          .range((page - 1) * limit, page * limit - 1)
          .limit(limit)
          .count();
    }

    const domain = 'https://cdn-dev.picnic.fan';

    for (var element in response.data) {
      element['vote_item'].forEach((item) {
        item['mystar_member']['image'] =
            '$domain/mystar/member/${item['mystar_member']['id']}/${item['mystar_member']['image']}';
      });
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
