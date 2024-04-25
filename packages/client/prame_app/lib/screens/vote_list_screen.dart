import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/pages/article_page.dart';
import 'package:prame_app/pages/vote_list_page.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';
import 'package:prame_app/ui/style.dart';

class VoteListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/vote-list';

  const VoteListScreen({super.key});

  @override
  ConsumerState<VoteListScreen> createState() => _VoteListScreenState();
}

class _VoteListScreenState extends ConsumerState<VoteListScreen>
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: _buildPage(ref),
    );
  }

  AppBar _buildAppBar(context, WidgetRef ref) {
    return AppBar(
      title: Text(
        Intl.message('label_vote_screen_title'),
        style: getTextStyle(context, AppTypo.UI20B, AppColors.Gray900),
      ),
    );
  }

  Widget _buildPage(ref) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(
            unselectedLabelColor: Colors.grey,
            controller: _tabController,
            indicatorWeight: 1,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(0),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              Align(
                  alignment: Alignment.center,
                  child: Text(Intl.message('label_vote_tab_birthday'),
                      style: const TextStyle(
                        fontSize: 16,
                      ))),
              Align(
                  alignment: Alignment.center,
                  child: Text(Intl.message('label_vote_tab_prame'),
                      style: const TextStyle(
                        fontSize: 16,
                      ))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBirthdayTab(),
              _buildPrameTab(ref),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBirthdayTab() {
    return VoteListPage(
      category: 'birthday',
    );
  }

  Widget _buildPrameTab(ref) {
    return VoteListPage(
      category: 'prame',
    );
  }
}

class VoteListScreenArguments {
  final int galleryId;
  final String galleryName;

  VoteListScreenArguments({required this.galleryId, required this.galleryName});
}
