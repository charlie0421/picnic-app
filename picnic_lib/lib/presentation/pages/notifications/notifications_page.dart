import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picnic_lib/presentation/pages/community/community_post_detail_screen.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final List<UserNotification> _items = [];
  bool _isInitialLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _from = 0;
  final int _limit = 20;
  final ScrollController _controller = ScrollController();
  String? _pageTitle;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 200 &&
          !_isMoreLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageTitle ??= AppLocalizations.of(context).label_mypage_notifications;
    _updateNavigationTitle();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _items.clear();
      _from = 0;
      _hasMore = true;
    });
    final list = await NotificationInboxService.fetch(
      from: _from,
      limit: _limit,
    );
    setState(() {
      _items.addAll(list);
      _from += list.length;
      _hasMore = list.length == _limit;
      _isInitialLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isMoreLoading || !_hasMore) return;
    setState(() => _isMoreLoading = true);
    final list = await NotificationInboxService.fetch(
      from: _from,
      limit: _limit,
    );
    setState(() {
      _items.addAll(list);
      _from += list.length;
      _hasMore = list.length == _limit;
      _isMoreLoading = false;
    });
  }

  Future<void> _markRead(UserNotification n) async {
    final ok = await NotificationInboxService.markRead(n.id);
    if (ok) {
      setState(() {
        final idx = _items.indexWhere((e) => e.id == n.id);
        if (idx >= 0) {
          _items[idx] = _items[idx].copyWith(
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
          );
        }
      });
    } else {
      logger.w('mark read failed');
    }
  }

  Future<bool> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isPicnicDomain =
          host == 'applink.picnic.fan' || host == 'www.picnic.fan';

      // Picnic 도메인의 앱 내부 경로는 deep link로 처리
      if (isPicnicDomain && (uri.scheme == 'https' || uri.scheme == 'http')) {
        logger.i('Deep link 처리: $url');
        await AppInitializer.handleDeepLink(ref, url);
        return true;
      } else if (await canLaunchUrl(uri)) {
        // 외부 URL은 외부 브라우저로 열기
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        logger.w('Cannot launch URL: $url');
      }
    } catch (e, s) {
      logger.e('open url failed', error: e, stackTrace: s);
    }

    return false;
  }

  Future<void> _navigateByType(UserNotification n) async {
    final data = n.data ?? const {};
    try {
      switch (n.type) {
        case 'vote':
        case 'my_artist_vote_start':
        case 'vote_progress':
          final voteIdStr = (data['vote_id'] ?? data['id'])?.toString();
          final voteId = voteIdStr != null ? int.tryParse(voteIdStr) : null;
          if (voteId != null) {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VoteDetailPage(voteId: voteId)),
            );
          }
          break;
        case 'post':
          final postId = (data['post_id'] ?? data['id'])?.toString();
          if (postId != null && postId.isNotEmpty) {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommunityPostDetailScreen(postId: postId),
              ),
            );
          }
          break;
        case 'qna':
        case 'question_created':
        case 'answer_created':
          final qidStr = (data['question_id'] ?? data['id'])?.toString();
          if (qidStr != null && qidStr.isNotEmpty) {
            final repo = QnaRepository();
            final threadId = int.tryParse(qidStr);
            if (threadId != null) {
              final withMsgs = await repo.getQaThreadById(threadId);
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QnaThreadDetailPage(thread: withMsgs.thread),
                ),
              );
            }
          }
          break;
        default:
          logger.i('Unhandled notif type=${n.type} data=${n.data}');
      }
    } catch (e, s) {
      logger.e('navigateByType failed', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    // MyPageScreen이 AppBar를 제공하므로 Scaffold 없이 body만 반환
    if (_isInitialLoading) {
      return _buildShimmer();
    }

    if (_items.isEmpty) {
      return NoItemContainer(
        message: AppLocalizations.of(context).common_text_no_data,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.separated(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: _items.length + (_isMoreLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: const CircularProgressIndicator(),
              ),
            );
          }
          return _buildNotificationCard(_items[index]);
        },
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16.h,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8.h),
                        Container(width: 150.w, height: 12.h, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
      ),
    );
  }

  Widget _buildNotificationCard(UserNotification n) {
    IconData leadingIcon;
    Color iconBgColor;
    Color iconColor;

    switch (n.type) {
      case 'vote':
      case 'my_artist_vote_start':
      case 'vote_progress':
        leadingIcon = Icons.how_to_vote;
        iconBgColor = Colors.indigo.withValues(alpha: 0.1);
        iconColor = Colors.indigo;
        break;
      case 'qna':
      case 'answer_created':
      case 'question_created':
        leadingIcon = Icons.question_answer;
        iconBgColor = Colors.teal.withValues(alpha: 0.1);
        iconColor = Colors.teal;
        break;
      case 'post':
        leadingIcon = Icons.post_add;
        iconBgColor = Colors.deepPurple.withValues(alpha: 0.1);
        iconColor = Colors.deepPurple;
        break;
      default:
        leadingIcon = Icons.notifications;
        iconBgColor = AppColors.primary500.withValues(alpha: 0.1);
        iconColor = AppColors.primary500;
    }

    final localizedTitle = n.getLocalizedTitle(context);
    final localizedBody = n.getLocalizedBody(context);
    final createdAt = n.createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(n.createdAt!).toLocal())
        : '';

    return InkWell(
      onTap: () async {
        if (!n.isRead) {
          await _markRead(n);
        }
        if ((n.actionUrl ?? '').isNotEmpty) {
          final handledInternally = await _openUrl(n.actionUrl!);
          if (handledInternally && mounted && context.mounted) {
            await Navigator.of(context).maybePop();
          }
        } else if ((n.data ?? {}).isNotEmpty) {
          await _navigateByType(n);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : AppColors.primary500.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: n.isRead
              ? null
              : Border.all(color: AppColors.primary500.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                leadingIcon,
                size: 20.w,
                color: iconColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizedTitle,
                          style: getTextStyle(
                            n.isRead ? AppTypo.body14M : AppTypo.body14B,
                            AppColors.grey900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          margin: EdgeInsets.only(left: 8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    localizedBody,
                    style: getTextStyle(AppTypo.body14R, AppColors.grey600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12.w, color: AppColors.grey500),
                      SizedBox(width: 4.w),
                      Text(
                        createdAt,
                        style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNavigationTitle() {
    final title = _pageTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: title);
    });
  }
}
