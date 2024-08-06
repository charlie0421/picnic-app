import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/mypage/vote_my_artist_search.dart';
import 'package:picnic_app/generated/l10n.dart';

class VoteMyArtist extends ConsumerStatefulWidget {
  const VoteMyArtist({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteMyArtist>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  Widget _buildPage() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: S.of(context).label_tab_my_artist,
              ),
              Tab(
                text: S.of(context).label_tab_search_my_artist,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Container(),
              const VoteMyArtistSearch(),
            ],
          ),
        )
      ],
    );
  }
}
