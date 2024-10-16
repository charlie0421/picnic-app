import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

import '../../../util/logger.dart';

class VoteList extends ConsumerStatefulWidget {
  final VoteStatus status;
  final VoteCategory category;

  const VoteList(this.status, this.category, {super.key});

  @override
  ConsumerState<VoteList> createState() => _VoteListState();
}

class _VoteListState extends ConsumerState<VoteList> {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(
        (pageKey) => _fetch(pageKey, status: widget.status));
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
        firstPageErrorIndicatorBuilder: (context) => ErrorView(
          context,
          error: _pagingController.error.toString(),
          retryFunction: () => _pagingController.refresh(),
          stackTrace: _pagingController.error.stackTrace,
        ),
        firstPageProgressIndicatorBuilder: (context) =>
            SizedBox(height: 400, child: buildLoadingOverlay()),
        noItemsFoundIndicatorBuilder: (context) => _buildNoItemsFound(context),
        itemBuilder: (context, item, index) => Column(
          children: [
            VoteInfoCard(context: context, vote: item, status: widget.status),
            const Divider(height: 1, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }

  Widget _buildNoItemsFound(BuildContext context) {
    String message;
    switch (widget.status) {
      case VoteStatus.active:
        message = S.of(context).message_noitem_vote_active;
        break;
      case VoteStatus.end:
        message = S.of(context).message_noitem_vote_end;
        break;
      case VoteStatus.upcoming:
        message = S.of(context).message_noitem_vote_upcoming;
        break;
      default:
        return Container();
    }
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(message,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey500)),
    );
  }

  Future<void> _fetch(int pageKey, {required VoteStatus status}) async {
    try {
      final newItems = await ref.read(asyncVoteListProvider(
        pageKey,
        _pageSize,
        'id',
        'DESC',
        status: status,
        category: VoteCategory.all,
      ).future);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (e, s) {
      _pagingController.error = e;
      logger.e(e, stackTrace: s);
    }
  }
}
