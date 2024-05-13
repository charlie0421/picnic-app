import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/components/vote/list/vote_artists.dart';
import 'package:prame_app/components/vote/list/vote_image.dart';
import 'package:prame_app/components/vote/list/vote_title.dart';
import 'package:prame_app/models/vote/vote.dart';
import 'package:prame_app/providers/vote_list_provider.dart';
import 'package:prame_app/util.dart';

class VoteHomePage extends ConsumerStatefulWidget {
  const VoteHomePage({super.key});

  @override
  ConsumerState<VoteHomePage> createState() => _VoteHomePageState();
}

class _VoteHomePageState extends ConsumerState<VoteHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.menu),
            Icon(Icons.calendar_month),
          ],
        ),
      ),
      SizedBox(
        height: 200,
        child: Swiper(
          itemBuilder: (BuildContext context, int index) {
            return Image.network(
              'https://picsum.photos/250?image=$index',
              fit: BoxFit.fill,
            );
          },
          itemCount: 10,
          itemHeight: 200.0,
          autoplay: true,
          pagination: SwiperPagination(),
          layout: SwiperLayout.DEFAULT,
        ),
      ),
      SizedBox(
        height: 130,
        child: Column(
          children: [
            Text('리워드 LIST'),
            Container(
              height: 100,
              width: 400,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      width: 100,
                      height: 40,
                      color: Colors.blue,
                      margin: EdgeInsets.all(8),
                    );
                  }),
            ),
          ],
        ),
      ),
      const Divider(thickness: 0.5, color: Colors.grey),
      ref.watch(asyncVoteListProvider(category: 'all')).when(
            data: (pagingController) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        return ErrorView(context,
                            error: 'No Items Found', stackTrace: null);
                      },
                      itemBuilder: (context, item, index) =>
                          _buildVote(context, ref, item)),
                )),
            loading: () => buildLoadingOverlay(),
            error: (error, stackTrace) => ErrorView(context,
                error: error.toString(), stackTrace: stackTrace),
          ),
    ]);
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
}
