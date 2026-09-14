import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/inbox_notification.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/community/community_post_detail_screen.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher.dart';

enum NotificationsPageMode { standalone, embedded }

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({
    super.key,
    this.service,
    this.mode = NotificationsPageMode.standalone,
  });

  final NotificationInboxService? service;
  final NotificationsPageMode mode;

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const int _limit = 20;

  final List<InboxNotification> _items = [];
  final ScrollController _controller = ScrollController();
  final Map<NotificationInboxPager, Future<void>> _firstPageLoads = {};
  late final NotificationInboxService _service;
  late NotificationInboxPager _pager;
  bool _initialLoading = true;
  bool _appendLoading = false;
  bool _initialError = false;
  bool _appendError = false;
  bool _hasMore = true;
  bool _markAllLoading = false;
  int _generation = 0;
  String? _pageTitle;

  String? _extractEmoji(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );
    return emojiRegex.firstMatch(text)?.group(0);
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NotificationInboxService();
    _pager = _service.createPager(accountId: _service.currentAccountId);
    _controller.addListener(_onScroll);
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _generation++;
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageTitle ??= AppLocalizations.of(context).label_mypage_notifications;
    _updateNavigationTitle();
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage() {
    final pager = _pager;
    final pending = _firstPageLoads[pager];
    if (pending != null) return pending;

    late final Future<void> tracked;
    tracked = _performFirstPageLoad(pager).whenComplete(() {
      if (identical(_firstPageLoads[pager], tracked)) {
        _firstPageLoads.remove(pager);
      }
    });
    _firstPageLoads[pager] = tracked;
    return tracked;
  }

  Future<void> _performFirstPageLoad(NotificationInboxPager pager) async {
    final generation = ++_generation;
    final accountId = pager.accountId;
    if (mounted) {
      setState(() {
        _initialLoading = _items.isEmpty;
        _appendLoading = false;
        _initialError = false;
        _appendError = false;
      });
    }
    try {
      final page = await pager.nextPage(limit: _limit);
      if (!_isCurrent(generation, pager, accountId)) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _initialLoading = false;
        _initialError = false;
      });
    } catch (error, stackTrace) {
      if (!_isCurrent(generation, pager, accountId)) return;
      logger.e(
        'notification first page failed',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() {
        _initialLoading = false;
        _initialError = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_initialLoading ||
        _firstPageLoads.containsKey(_pager) ||
        _appendLoading ||
        !_hasMore) {
      return;
    }
    final generation = _generation;
    final pager = _pager;
    final accountId = pager.accountId;
    setState(() {
      _appendLoading = true;
      _appendError = false;
    });
    try {
      final page = await pager.nextPage(limit: _limit);
      if (!_isCurrent(generation, pager, accountId)) return;
      setState(() {
        final identities = _items.map((item) => item.identity).toSet();
        _items.addAll(
          page.items.where((item) => identities.add(item.identity)),
        );
        _hasMore = page.hasMore;
        _appendLoading = false;
      });
    } catch (error, stackTrace) {
      if (!_isCurrent(generation, pager, accountId)) return;
      logger.e(
        'notification next page failed',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() {
        _appendLoading = false;
        _appendError = true;
      });
    }
  }

  bool _isCurrent(
    int generation,
    NotificationInboxPager pager,
    String? accountId,
  ) {
    if (!mounted || generation != _generation || !identical(pager, _pager)) {
      return false;
    }
    if (_service.currentAccountId != accountId) {
      _restartForCurrentAccount();
      return false;
    }
    return true;
  }

  void _restartForCurrentAccount() {
    _generation++;
    _pager = _service.createPager(accountId: _service.currentAccountId);
    setState(() {
      _items.clear();
      _initialLoading = true;
      _appendLoading = false;
      _initialError = false;
      _appendError = false;
      _hasMore = true;
    });
    unawaited(_loadFirstPage());
  }

  Future<void> _refresh() async {
    _pager = _service.createPager(accountId: _service.currentAccountId);
    await _loadFirstPage();
    if (mounted) ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> _markRead(InboxNotification notification) async {
    final accountId = _service.currentAccountId;
    final ok = await _service.markNotificationRead(notification);
    if (!mounted || !ok || _service.currentAccountId != accountId) return;
    setState(() {
      final index = _items.indexWhere(
        (item) => item.identity == notification.identity,
      );
      if (index >= 0) _items[index] = _items[index].markedRead();
    });
    if (notification.source == NotificationSource.personal) {
      ref.invalidate(unreadNotificationsCountProvider);
    }
  }

  Future<void> _markAllRead() async {
    if (_markAllLoading) return;
    setState(() => _markAllLoading = true);
    try {
      final pagerAtStart = _pager;
      final visibleAtStart = _items.map((item) => item.identity).toSet();
      final bufferedPersonalAtStart = pagerAtStart
          .snapshotBufferedPersonalIds();
      final result = await _service.markAllNotificationsRead();
      if (!mounted || !result.accountStillCurrent) return;
      final personalOverlayIds = result.personalReadIds.toSet();
      if (result.personalSucceeded && identical(_pager, pagerAtStart)) {
        personalOverlayIds.addAll(bufferedPersonalAtStart);
      }
      _pager.applyReadIds(
        personalIds: personalOverlayIds,
        broadcastIds: result.broadcastReadIds,
      );
      setState(() {
        for (var index = 0; index < _items.length; index++) {
          final item = _items[index];
          final succeeded = item.source == NotificationSource.personal
              ? result.personalSucceeded
              : result.broadcastSucceeded;
          final wasTargeted = visibleAtStart.contains(item.identity);
          final broadcastWasScanned = result.broadcastReadIds.contains(item.id);
          if (succeeded &&
              wasTargeted &&
              (item.source == NotificationSource.personal ||
                  broadcastWasScanned) &&
              !item.isRead) {
            _items[index] = item.markedRead();
          }
        }
      });
      if (result.personalSucceeded) {
        ref.invalidate(unreadNotificationsCountProvider);
      }
    } finally {
      if (mounted) setState(() => _markAllLoading = false);
    }
  }

  Future<bool> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isPicnicDomain =
          host == 'applink.picnic.fan' || host == 'www.picnic.fan';
      if (isPicnicDomain && (uri.scheme == 'https' || uri.scheme == 'http')) {
        await AppInitializer.handleDeepLink(ref, url);
        return true;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (error, stackTrace) {
      logger.e('open url failed', error: error, stackTrace: stackTrace);
    }
    return false;
  }

  Future<void> _navigateByType(InboxNotification notification) async {
    final data = notification.data ?? const {};
    try {
      switch (notification.type) {
        case 'vote':
          final voteId = int.tryParse('${data['vote_id'] ?? data['id'] ?? ''}');
          if (voteId != null && mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VoteDetailPage(voteId: voteId)),
            );
          }
          break;
        case 'post':
          final postId = '${data['post_id'] ?? data['id'] ?? ''}';
          if (postId.isNotEmpty && mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommunityPostDetailScreen(postId: postId),
              ),
            );
          }
          break;
        case 'qna':
        case 'question_created':
        case 'answer_created':
          final threadId = int.tryParse(
            '${data['question_id'] ?? data['id'] ?? ''}',
          );
          if (threadId != null) {
            final withMessages = await QnaRepository().getQaThreadById(
              threadId,
            );
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    QnaThreadDetailPage(thread: withMessages.thread),
              ),
            );
          }
          break;
        default:
          logger.i(
            'Unhandled notif type=${notification.type} data=${notification.data}',
          );
      }
    } catch (error, stackTrace) {
      logger.e('navigateByType failed', error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == NotificationsPageMode.embedded) {
      return ColoredBox(
        color: PicnicUi.surface,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _buildMarkAllAction(),
            ),
            Divider(height: 1, color: PicnicUi.border),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: PicnicUi.surface,
      appBar: AppBar(
        backgroundColor: PicnicUi.surface,
        foregroundColor: PicnicUi.ink,
        title: Text(
          _pageTitle ?? AppLocalizations.of(context).label_mypage_notifications,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PicnicUi.text(size: 16, weight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [_buildMarkAllAction()],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildMarkAllAction() {
    final label = AppLocalizations.of(context).notifications_mark_all_read;
    return TextButton(
      key: const ValueKey('notifications-mark-all'),
      onPressed: _markAllLoading ? null : _markAllRead,
      style: TextButton.styleFrom(
        foregroundColor: PicnicUi.actionColor,
        disabledForegroundColor: PicnicUi.secondaryText,
        minimumSize: const Size.square(PicnicUi.minimumTapTarget),
        padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(12)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: PicnicUi.text(
          weight: FontWeight.w600,
          color: _markAllLoading
              ? PicnicUi.secondaryText
              : PicnicUi.actionColor,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoading && _items.isEmpty) {
      return const Center(child: MediumPulseLoadingIndicator());
    }
    if (_initialError && _items.isEmpty) {
      return _scrollableMessage(
        child: PicnicFeedback(
          icon: Icons.error_outline,
          message: AppLocalizations.of(context).message_error_occurred,
          actionLabel: AppLocalizations.of(context).retry,
          onAction: _loadFirstPage,
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(PicnicUi.horizontal(24)),
                  child: PicnicFeedback(
                    icon: Icons.notifications_none,
                    message: AppLocalizations.of(context).common_text_no_data,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final showRefreshError = _initialError && _items.isNotEmpty;
    final showAppendFooter = _appendLoading || _appendError;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            _items.length +
            (showRefreshError ? 1 : 0) +
            (showAppendFooter ? 1 : 0),
        separatorBuilder: (_, _) => Divider(height: 1, color: PicnicUi.border),
        itemBuilder: (context, index) {
          if (showRefreshError && index == 0) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PicnicUi.horizontal(16),
                vertical: PicnicUi.vertical(8),
              ),
              child: PicnicFeedback(
                inline: true,
                icon: Icons.error_outline,
                message: AppLocalizations.of(context).message_error_occurred,
                actionLabel: AppLocalizations.of(context).retry,
                onAction: _loadFirstPage,
              ),
            );
          }
          final itemIndex = index - (showRefreshError ? 1 : 0);
          if (itemIndex == _items.length) {
            if (_appendError) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PicnicUi.horizontal(16),
                  vertical: PicnicUi.vertical(8),
                ),
                child: PicnicFeedback(
                  inline: true,
                  icon: Icons.error_outline,
                  message: AppLocalizations.of(context).message_error_occurred,
                  actionLabel: AppLocalizations.of(context).retry,
                  onAction: _loadMore,
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.all(PicnicUi.horizontal(16)),
              child: const Center(child: MediumPulseLoadingIndicator()),
            );
          }
          return _buildNotificationTile(_items[itemIndex]);
        },
      ),
    );
  }

  Widget _scrollableMessage({required Widget child}) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(PicnicUi.horizontal(24)),
            child: child,
          ),
        ),
      ),
    ],
  );

  Widget _buildNotificationTile(InboxNotification notification) {
    final localizedTitle = notification.getLocalizedTitle(context);
    final localizedBody = notification.getLocalizedBody(context);
    final emoji = _extractEmoji(localizedTitle);
    final displayTitle = emoji == null
        ? localizedTitle
        : localizedTitle.replaceFirst(emoji, '').trim();
    final isUnread = !notification.isRead;
    final tileColor = isUnread
        ? Color.alphaBlend(
            AppColors.primary500.withValues(alpha: 0.08),
            PicnicUi.surface,
          )
        : PicnicUi.surface;

    IconData fallbackIcon;
    switch (notification.type) {
      case 'vote':
        fallbackIcon = Icons.how_to_vote;
        break;
      case 'qna':
      case 'answer_created':
      case 'question_created':
        fallbackIcon = Icons.question_answer;
        break;
      case 'post':
        fallbackIcon = Icons.post_add;
        break;
      default:
        fallbackIcon = Icons.notifications;
    }

    Widget leading = emoji == null
        ? Icon(
            fallbackIcon,
            color: isUnread ? PicnicUi.actionColor : PicnicUi.quietText,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(emoji, style: const TextStyle(fontSize: 28, height: 1)),
          );
    if (isUnread) {
      leading = Stack(
        clipBehavior: Clip.none,
        children: [
          leading,
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.statusError,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    return ListTile(
      key: ValueKey(notification.identity),
      contentPadding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(16),
        vertical: PicnicUi.vertical(4),
      ),
      leading: SizedBox(width: 40, height: 40, child: Center(child: leading)),
      tileColor: tileColor,
      title: Text(
        displayTitle,
        style: PicnicUi.text(
          weight: isUnread ? FontWeight.w700 : FontWeight.w500,
          color: isUnread ? PicnicUi.ink : PicnicUi.secondaryText,
        ),
      ),
      subtitle: Text(
        localizedBody,
        style: PicnicUi.text(
          size: 12,
          color: isUnread ? PicnicUi.secondaryText : PicnicUi.quietText,
        ),
      ),
      onTap: () async {
        if (!notification.isRead) await _markRead(notification);
        if ((notification.actionUrl ?? '').isNotEmpty) {
          final handled = await _openUrl(notification.actionUrl!);
          if (handled && mounted && context.mounted) {
            await Navigator.of(context).maybePop();
          }
        } else if ((notification.data ?? {}).isNotEmpty) {
          await _navigateByType(notification);
        }
      },
    );
  }

  void _updateNavigationTitle() {
    final title = _pageTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: title);
    });
  }
}
