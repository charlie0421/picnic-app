import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';

class VoteList extends ConsumerStatefulWidget {
  final VoteStatus status;
  final VoteCategory category;
  final String area;

  const VoteList(this.status, this.category, this.area, {super.key});

  @override
  ConsumerState<VoteList> createState() => _VoteListState();
}

class _VoteListState extends ConsumerState<VoteList> {
  final List<VoteModel> _items = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _pageKey = 1;
  static const _pageSize = 10;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchVotes();
  }

  Future<void> _fetchVotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final newItems = await ref.read(asyncVoteListProvider(
        _pageKey,
        _pageSize,
        'id',
        'DESC',
        widget.area,
        status: widget.status,
        category: widget.category,
      ).future);

      setState(() {
        _items.addAll(newItems);
        _isLoading = false;
        _isFetchingMore = false;
        if (newItems.isNotEmpty) {
          _pageKey++;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _onPageChanged(int index) {
    // 마지막 아이템에 도달하면 추가 fetch
    if (!_isFetchingMore && index == _items.length - 1) {
      setState(() {
        _isFetchingMore = true;
      });
      _fetchVotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return VoteNoItem(status: widget.status, context: context);
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _items.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VoteInfoCard(
                  context: context,
                  vote: item,
                  status: widget.status,
                ),
              ],
            );
          },
        ),
        if (_isFetchingMore)
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
