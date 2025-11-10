import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
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
  bool _loading = false;
  int _from = 0;
  final int _limit = 20;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 200 &&
          !_loading) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NotificationInboxService.fetch(
      from: _from,
      limit: _limit,
    );
    setState(() {
      _items.addAll(list);
      _from += list.length;
      _loading = false;
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

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isPicnicDomain = host == 'applink.picnic.fan' || host == 'www.picnic.fan';
      
      // Picnic 도메인의 앱 내부 경로는 deep link로 처리
      if (isPicnicDomain && (uri.scheme == 'https' || uri.scheme == 'http')) {
        logger.i('Deep link 처리: $url');
        await AppInitializer.handleDeepLink(ref, url);
      } else if (await canLaunchUrl(uri)) {
        // 외부 URL은 외부 브라우저로 열기
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        logger.w('Cannot launch URL: $url');
      }
    } catch (e, s) {
      logger.e('open url failed', error: e, stackTrace: s);
    }
  }

  Future<void> _navigateByType(UserNotification n) async {
    final data = n.data ?? const {};
    try {
      switch (n.type) {
        case 'vote':
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
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => PostViewPage(postId)));
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
    return Scaffold(
      appBar: AppBar(title: const Text('알림함')),
      body: ListView.separated(
        controller: _controller,
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final n = _items[index];
          IconData leadingIcon;
          Color? tileColor;
          switch (n.type) {
            case 'vote':
              leadingIcon = Icons.how_to_vote;
              tileColor = Colors.indigo.withValues(alpha: 0.05);
              break;
            case 'qna':
            case 'answer_created':
            case 'question_created':
              leadingIcon = Icons.question_answer;
              tileColor = Colors.teal.withValues(alpha: 0.05);
              break;
            case 'post':
              leadingIcon = Icons.post_add;
              tileColor = Colors.deepPurple.withValues(alpha: 0.05);
              break;
            default:
              leadingIcon = Icons.notifications;
              tileColor = null;
          }

          // 다국어 처리: 현재 로케일에 맞는 텍스트 표시
          final localizedTitle = n.getLocalizedTitle(context);
          final localizedBody = n.getLocalizedBody(context);
          
          return ListTile(
            leading: Icon(leadingIcon),
            tileColor: tileColor,
            title: Text(
              localizedTitle,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(localizedBody),
            onTap: () {
              if ((n.actionUrl ?? '').isNotEmpty) {
                _openUrl(n.actionUrl!);
              } else if ((n.data ?? {}).isNotEmpty) {
                _navigateByType(n);
              }
            },
            trailing: (n.userId != null && !n.isRead)
                ? null
                : TextButton(
                    onPressed: () => _markRead(n),
                    child: const Text('읽음'),
                  ),
          );
        },
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemCount: _items.length + 1,
      ),
    );
  }
}
