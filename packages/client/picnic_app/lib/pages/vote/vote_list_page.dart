import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/vote/list/vote_artists.dart';
import 'package:picnic_app/components/vote/list/vote_header.dart';
import 'package:picnic_app/components/vote/list/vote_image.dart';
import 'package:picnic_app/components/vote/list/vote_list.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';

class VoteListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(controller: _tabController, tabs: [
            Tab(text: Intl.message('label_tabbar_vote_active')),
            Tab(text: Intl.message('label_tabbar_vote_end')),
          ]),
        ),
        SizedBox(
          height: 36.w,
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: const [
          VoteList(VoteStatus.active, VoteCategory.all),
          VoteList(VoteStatus.end, VoteCategory.all),
        ]))
      ],
    );
  }
}

Widget _buildVote(BuildContext context, WidgetRef ref, VoteModel vote) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    child: Column(
      children: [
        VoteHeader(vote: vote),
        SizedBox(
          height: 10.w,
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
