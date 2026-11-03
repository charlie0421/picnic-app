import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef NoticeDetailLoader =
    Future<Map<String, dynamic>?> Function(int noticeId);

class NoticeDetailPage extends ConsumerStatefulWidget {
  const NoticeDetailPage({super.key, required this.noticeId, this.loadNotice});

  final int noticeId;
  final NoticeDetailLoader? loadNotice;

  @override
  ConsumerState<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends ConsumerState<NoticeDetailPage>
    with RouteAwareStateMixin<NoticeDetailPage> {
  Map<String, dynamic>? _notice;
  bool _loading = true;
  Object? _error;
  String? _prevPageTitle;
  String? _currentTitle;
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
      // 현재 페이지 타이틀을 저장해두었다가, 뒤로가기 시 복원한다
      _prevPageTitle = ref.read(navigationInfoProvider).pageTitle;
      final title = AppLocalizations.of(context).label_mypage_notice;
      _currentTitle = title;
      _applyNavigation(title);
      _fetchDetail();
    });
  }

  @override
  void dispose() {
    _loadGeneration++;
    // 복원 로직은 PopScope.onPopInvoked에서 처리
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentTitle != null) {
      _applyNavigation(_currentTitle);
    }
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    if (_currentTitle != null) {
      _applyNavigation(_currentTitle);
    }
  }

  Future<void> _fetchDetail() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final notice =
          await (widget.loadNotice?.call(widget.noticeId) ??
              _loadNotice(widget.noticeId));
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _notice = notice;
        _loading = false;
      });
    } catch (error, stackTrace) {
      logger.e('공지사항 상세 데이터 가져오기 오류', error: error, stackTrace: stackTrace);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadNotice(int noticeId) async {
    final response = await Supabase.instance.client
        .from('notices')
        .select()
        .eq('id', noticeId)
        .maybeSingle();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: MediumPulseLoadingIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.all(PicnicUi.horizontal(24)),
          child: PicnicFeedback(
            key: const ValueKey('notice-detail-retry'),
            icon: Icons.error_outline,
            message: AppLocalizations.of(context).message_error_occurred,
            actionLabel: AppLocalizations.of(context).label_retry,
            onAction: _fetchDetail,
          ),
        ),
      );
    } else if (_notice == null) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.all(PicnicUi.horizontal(24)),
          child: PicnicFeedback(
            icon: Icons.description_outlined,
            message: AppLocalizations.of(context).common_text_no_search_result,
          ),
        ),
      );
    } else {
      final language = Localizations.localeOf(context).languageCode;
      final title = _getLocalizedText(_notice!['title'] ?? {}, language);
      final content = _getLocalizedText(_notice!['content'] ?? {}, language);
      final createdAt =
          _notice!['created_at']?.toString().substring(0, 10) ?? '';

      body = SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(16),
          vertical: PicnicUi.vertical(16),
        ),
        child: PicnicSurface(
          padding: EdgeInsets.all(PicnicUi.horizontal(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PicnicUi.text(size: 18, weight: FontWeight.w700),
              ),
              SizedBox(height: PicnicUi.vertical(8)),
              Text(
                createdAt,
                style: PicnicUi.text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: PicnicUi.quietText,
                ),
              ),
              SizedBox(height: PicnicUi.vertical(16)),
              Text(content, style: PicnicUi.text()),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final restoreTitle = _prevPageTitle ?? '';
          ref
              .read(navigationInfoProvider.notifier)
              .setPageTitle(pageTitle: restoreTitle);
        }
      },
      child: body,
    );
  }

  void _applyNavigation(String? title) {
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = ref.read(navigationInfoProvider.notifier);
      nav.setMyPageTitle(pageTitle: title);
      nav.settingNavigation(
        showPortal: false,
        showBottomNavigation: true,
        showTopMenu: true,
        pageTitle: title,
      );
    });
  }
}
