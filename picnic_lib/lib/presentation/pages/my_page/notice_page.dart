import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_status_badge.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

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
      return const Center(child: MediumPulseLoadingIndicator());
    }
    if (_loadError != null && sortedNotices.isEmpty) {
      return _buildError(context);
    }

    return RefreshIndicator(
      onRefresh: _fetchPage,
      child: sortedNotices.isNotEmpty
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: PicnicUi.horizontal(16),
                vertical: PicnicUi.vertical(16),
              ),
              itemCount: sortedNotices.length + (_loadError == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (_loadError != null && index == 0) {
                  return _buildError(context, compact: true);
                }
                final noticeIndex = index - (_loadError == null ? 0 : 1);
                final notice = sortedNotices[noticeIndex];
                final isPinned = notice['is_pinned'] == true;
                return Padding(
                  padding: EdgeInsets.only(bottom: PicnicUi.vertical(12)),
                  child: PicnicSurface(
                    radius: 12,
                    color: isPinned
                        ? AppColors.primary500.withValues(alpha: 0.06)
                        : null,
                    child: ExpansionTile(
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      iconColor: PicnicUi.actionColor,
                      collapsedIconColor: PicnicUi.quietText,
                      shape: const RoundedRectangleBorder(),
                      collapsedShape: const RoundedRectangleBorder(),
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: PicnicUi.horizontal(16),
                        vertical: PicnicUi.vertical(4),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPinned)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: PicnicUi.vertical(4),
                              ),
                              child: PicnicStatusBadge(
                                label: AppLocalizations.of(
                                  context,
                                ).notice_pinned,
                                backgroundColor: AppColors.primary500,
                              ),
                            ),
                          Text(
                            _getLocalizedText(notice['title'], currentLanguage),
                            style: PicnicUi.text(weight: FontWeight.w700),
                          ),
                          SizedBox(height: PicnicUi.vertical(4)),
                          Text(
                            notice['created_at']?.toString().substring(0, 10) ??
                                '',
                            style: PicnicUi.text(
                              size: 12,
                              weight: FontWeight.w500,
                              color: PicnicUi.quietText,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            PicnicUi.horizontal(16),
                            0,
                            PicnicUi.horizontal(16),
                            PicnicUi.vertical(16),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _getLocalizedText(
                                notice['content'],
                                currentLanguage,
                              ),
                              style: PicnicUi.text(
                                color: PicnicUi.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(PicnicUi.horizontal(24)),
                      child: PicnicFeedback(
                        icon: Icons.description_outlined,
                        message: AppLocalizations.of(
                          context,
                        ).common_text_no_search_result,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError(BuildContext context, {bool compact = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          compact ? PicnicUi.horizontal(8) : PicnicUi.horizontal(24),
        ),
        child: PicnicFeedback(
          key: const ValueKey('notice-retry'),
          inline: compact,
          icon: Icons.error_outline,
          message: AppLocalizations.of(context).message_error_occurred,
          actionLabel: AppLocalizations.of(context).label_retry,
          onAction: _fetchPage,
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
