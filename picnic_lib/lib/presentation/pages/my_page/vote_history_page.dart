import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/custom_dropdown_button.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_history_list_item.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

class VoteHistoryPage extends ConsumerStatefulWidget {
  const VoteHistoryPage({super.key});

  @override
  ConsumerState createState() => _VoteHistoryPageState();
}

class _VoteHistoryPageState extends ConsumerState<VoteHistoryPage>
    with RouteAwareStateMixin<VoteHistoryPage> {
  late final PagingController<int, VotePickModel> _pagingController =
      PagingController<int, VotePickModel>(
    getNextPageKey: (state) {
      if (state.items == null) return 1;
      final isLastPage = state.items!.length < _pageSize;
      if (isLastPage) return null;
      return (state.keys?.last ?? 0) + 1;
    },
    fetchPage: _fetch,
  );
  String _sortOrder = 'DESC';
  static const int _pageSize = 10;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).label_mypage_vote_history;
      _updateNavigation();
      _pagingController.fetchNextPage();
    });
  }

  Future<List<VotePickModel>> _fetch(int pageKey) async {
    try {
      final response = await supabase
          .from('vote_pick')
          .select(
              'id,amount,star_candy_usage,star_candy_bonus_usage,created_at,updated_at,vote(id,title,vote_category,main_image,wait_image,result_image,vote_content,created_at,visible_at,is_partnership,partner),vote_item(id,vote_total,star_candy_total,star_candy_bonus_total,vote_id,artist(id,name,yy,mm,dd,birth_date,gender,image,created_at,updated_at,deleted_at,artist_group(id,name,image,created_at,updated_at,deleted_at)),artist_group(id,name,image,created_at,updated_at,deleted_at))')
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('id', ascending: _sortOrder == 'ASC')
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1)
          .limit(_pageSize);

      final items = (response as List)
          .map((item) => VotePickModel.fromJson(item))
          .toList();

      return items;
    } catch (error) {
      logger.e(error);
      rethrow;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).label_mypage_vote_history;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.centerRight,
          child: CustomDropdown(
            key: const Key('sortOrderDropdown'),
            value: _sortOrder,
            onChanged: (value) {
              setState(() {
                _sortOrder = value.toString();
                _pagingController.refresh();
              });
            },
            items: [
              CustomDropdownMenuItem(
                value: 'DESC',
                text: AppLocalizations.of(context).label_dropdown_recent,
              ),
              CustomDropdownMenuItem(
                value: 'ASC',
                text: AppLocalizations.of(context).label_dropdown_oldest,
              ),
            ],
          ),
        ),
        Expanded(
          child: PagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) =>
                PagedListView<int, VotePickModel>(
              state: _pagingController.value,
              fetchNextPage: _pagingController.fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<VotePickModel>(
                itemBuilder: (context, item, index) =>
                    VoteHistoryListItem(item: item),
                noItemsFoundIndicatorBuilder: (context) =>
                    const NoItemContainer(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
          pageTitle: title);
    });
  }
}

