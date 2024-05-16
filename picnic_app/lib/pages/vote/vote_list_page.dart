import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_artists.dart';
import 'package:picnic_app/components/vote/list/vote_image.dart';
import 'package:picnic_app/components/vote/list/vote_title.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/util.dart';

class VoteListPage extends ConsumerStatefulWidget {
  final String category;

  const VoteListPage({super.key, required this.category});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage> {
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: VoteSortWidget(
        //     category: widget.category,
        //   ),
        // ),
        SizedBox(
          height: 20.h,
        ),
        Expanded(
            child: ref
                .watch(asyncVoteListProvider(category: widget.category))
                .when(
                  data: (pagingController) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: PagedListView<int, VoteModel>(
                        pagingController: pagingController,
                        scrollDirection: Axis.vertical,
                        builderDelegate: PagedChildBuilderDelegate<VoteModel>(
                            firstPageErrorIndicatorBuilder: (context) {
                              return ErrorView(context,
                                  error: pagingController.error.toString(),
                                  retryFunction: () =>
                                      pagingController.refresh(),
                                  stackTrace:
                                      pagingController.error.stackTrace);
                            },
                            firstPageProgressIndicatorBuilder: (context) {
                              return buildLoadingOverlay();
                            },
                            noItemsFoundIndicatorBuilder: (context) {
                              return ErrorView(context,
                                  error: 'No Items Found', stackTrace: null);
                            },
                            itemBuilder: (context, item, index) =>
                                _buildVote(context, ref, item)),
                      )),
                  loading: () => buildLoadingOverlay(),
                  error: (error, stackTrace) => ErrorView(context,
                      error: error.toString(), stackTrace: stackTrace),
                )),
      ],
    );
  }
}

Widget _buildVote(BuildContext context, WidgetRef ref, VoteModel vote) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    child: Column(
      children: [
        VoteTitle(vote: vote),
        SizedBox(
          height: 10.h,
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.withOpacity(1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VoteImage(vote: vote),
              VoteArtists(vote: vote),
              // VoteContent(vote: vote),
              // VoteBestComment(
              //     vote: vote, showComments: _showComments),
              // VoteCommentInfo(
              //     vote: vote, showComments: _showComments)
            ],
          ),
        ),
      ],
    ),
  );
}
