import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';

class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key});

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage> {
  List<Map<String, dynamic>> _notices = [];

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
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: t('label_mypage_notice'));
      _fetchPage();
    });
  }

  Future<void> _fetchPage() async {
    try {
      final response = await Supabase.instance.client
          .from('notices')
          .select()
          .eq('status', 'PUBLISHED')
          .order('created_at', ascending: false);

      setState(() {
        _notices = response;
        logger.i(_notices);
      });
    } catch (error) {
      logger.e('공지사항 데이터 가져오기 오류', error: error);
    }
  }

  List<Map<String, dynamic>> _getSortedNotices() {
    // 고정된 공지사항을 먼저 정렬하고, 그 다음에 일반 공지사항을 정렬
    final pinnedNotices =
        _notices.where((notice) => notice['is_pinned'] == true).toList();
    final normalNotices =
        _notices.where((notice) => notice['is_pinned'] != true).toList();
    return [...pinnedNotices, ...normalNotices];
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingProvider).language;
    final sortedNotices = _getSortedNotices();

    return sortedNotices.isNotEmpty
        ? ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: sortedNotices.length,
            itemBuilder: (context, index) {
              final notice = sortedNotices[index];
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
                              t('notice_pinned'),
                              style: getTextStyle(
                                  AppTypo.caption12M, AppColors.primary500),
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
                      style:
                          getTextStyle(AppTypo.caption12M, AppColors.grey500),
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
        : NoItemContainer(message: t('common_text_no_search_result'));
  }
}
