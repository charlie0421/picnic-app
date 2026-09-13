import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

typedef NoticeLoader = Future<List<Map<String, dynamic>>> Function();

class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key, this.loadNotices});

  final NoticeLoader? loadNotices;

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage>
    with RouteAwareStateMixin<NoticePage> {
  List<Map<String, dynamic>> _notices = [];
  String? _currentTitle;
  bool _isLoading = true;
  Object? _loadError;
  int _loadGeneration = 0;

  String _getLocalizedText(Map<String, dynamic> json, String language) {
    if (json[language] != null) {
      return json[language];
    }
    return json['en'] ?? '';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).label_mypage_notice;
      _updateNavigation();
      _fetchPage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).label_mypage_notice;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  Future<void> _fetchPage() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        if (_notices.isEmpty) _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final response = await (widget.loadNotices?.call() ?? _loadNotices());

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _notices = response;
        _isLoading = false;
        logger.i(_notices);
      });
    } catch (error) {
      logger.e('공지사항 데이터 가져오기 오류', error: error);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadNotices() async {
    final response = await Supabase.instance.client
        .from('notices')
        .select()
        .eq('status', 'PUBLISHED')
        .order('created_at', ascending: false);
    return response.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _getSortedNotices() {
    // 고정된 공지사항을 먼저 정렬하고, 그 다음에 일반 공지사항을 정렬
    final pinnedNotices = _notices
        .where((notice) => notice['is_pinned'] == true)
        .toList();
    final normalNotices = _notices
        .where((notice) => notice['is_pinned'] != true)
        .toList();
    return [...pinnedNotices, ...normalNotices];
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingProvider).language;
    final sortedNotices = _getSortedNotices();

    if (_isLoading && sortedNotices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null && sortedNotices.isEmpty) {
      return _buildError(context);
    }

    return RefreshIndicator(
      onRefresh: _fetchPage,
      child: sortedNotices.isNotEmpty
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: sortedNotices.length + (_loadError == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (_loadError != null && index == 0) {
                  return _buildError(context, compact: true);
                }
                final noticeIndex = index - (_loadError == null ? 0 : 1);
                final notice = sortedNotices[noticeIndex];
                return ExpansionTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notice['is_pinned'] == true)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 16.w,
                                color: AppColors.primary500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                AppLocalizations.of(context).notice_pinned,
                                style: getTextStyle(
                                  AppTypo.caption12M,
                                  AppColors.primary500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        _getLocalizedText(notice['title'], currentLanguage),
                        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notice['created_at']?.toString().substring(0, 10) ?? '',
                        style: getTextStyle(
                          AppTypo.caption12M,
                          AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        _getLocalizedText(notice['content'], currentLanguage),
                        style: getTextStyle(AppTypo.body14M, AppColors.grey700),
                      ),
                    ),
                  ],
                );
              },
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: NoItemContainer(
                    message: AppLocalizations.of(
                      context,
                    ).common_text_no_search_result,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError(BuildContext context, {bool compact = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).message_error_occurred,
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              key: const ValueKey('notice-retry'),
              onPressed: _fetchPage,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).label_retry),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: title);
    });
  }
}
