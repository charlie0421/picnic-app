import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_info_card.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/util.dart';

class VoteList extends ConsumerWidget {
  final VoteStatus status;
  final VoteCategory category;

  const VoteList(this.status, this.category, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(asyncVoteListProvider(category: category, status: status))
        .when(
          data: (pagingController) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: PagedListView<int, VoteModel>(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                pagingController: pagingController,
                scrollDirection: Axis.vertical,
                builderDelegate: PagedChildBuilderDelegate<VoteModel>(
                    firstPageErrorIndicatorBuilder: (context) {
                      return ErrorView(context,
                          error: pagingController.error.toString(),
                          retryFunction: () => pagingController.refresh(),
                          stackTrace: pagingController.error.stackTrace);
                    },
                    firstPageProgressIndicatorBuilder: (context) {
                      return buildLoadingOverlay();
                    },
                    noItemsFoundIndicatorBuilder: (context) {
                      return const Center(child: Text('No Items Found'));
                    },
                    itemBuilder: (context, item, index) =>
                        VoteInfoCard(context: context, ref: ref, vote: item)),
              )),
          loading: () => buildLoadingOverlay(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }
}
