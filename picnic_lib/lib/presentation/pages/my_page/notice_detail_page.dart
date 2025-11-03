import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoticeDetailPage extends ConsumerStatefulWidget {
  const NoticeDetailPage({super.key, required this.noticeId});

  final int noticeId;

  @override
  ConsumerState<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends ConsumerState<NoticeDetailPage> {
  Map<String, dynamic>? _notice;
  bool _loading = true;
  Object? _error;
  String? _prevPageTitle;

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
      final nav = ref.read(navigationInfoProvider.notifier);
      final title = AppLocalizations.of(context).label_mypage_notice;
      nav.setMyPageTitle(pageTitle: title);
      nav.settingNavigation(
        showPortal: false,
        showBottomNavigation: true,
        showTopMenu: true,
        pageTitle: title,
      );
      _fetchDetail();
    });
  }

  @override
  void dispose() {
    // 복원 로직은 PopScope.onPopInvoked에서 처리
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('notices')
          .select()
          .eq('id', widget.noticeId)
          .single();
      if (!mounted) return;
      setState(() {
        _notice = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || _notice == null) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            AppLocalizations.of(context).common_text_no_search_result,
            style: getTextStyle(AppTypo.body14M, AppColors.grey700),
            textAlign: TextAlign.center,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: getTextStyle(AppTypo.title18B, AppColors.grey900),
            ),
            SizedBox(height: 8.h),
            Text(
              createdAt,
              style: getTextStyle(AppTypo.caption12M, AppColors.grey500),
            ),
            SizedBox(height: 16.h),
            Text(
              content,
              style: getTextStyle(AppTypo.body14M, AppColors.grey800),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
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
}
