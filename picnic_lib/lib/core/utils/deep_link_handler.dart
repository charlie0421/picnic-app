import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/app_initializer_helper.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/pages/community/board_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_post_detail_screen.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_detail_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';

/// Deep link URL routing logic extracted from [AppInitializer].
///
/// Handles URL parsing, duplicate detection, and portal-specific navigation.
class DeepLinkHandler {
  // Duplicate deep link prevention state
  static String? _lastDeepLinkUrl;
  static DateTime? _lastDeepLinkTime;

  static Future<void> handleDeepLink(WidgetRef ref, String longUrl) async {
    try {
      final now = DateTime.now();
      if (AppInitializerHelper.isDuplicateDeepLink(
        url: longUrl,
        lastUrl: _lastDeepLinkUrl,
        lastTime: _lastDeepLinkTime,
        now: now,
      )) {
        logger.i('[DeepLink] Ignoring duplicate deep link: $longUrl');
        return;
      }
      _lastDeepLinkUrl = longUrl;
      _lastDeepLinkTime = now;

      final uri = Uri.parse(longUrl);
      final navigationNotifier = ref.read(navigationInfoProvider.notifier);

      if (uri.pathSegments.isNotEmpty) {
        final portal = uri.pathSegments[0];
        final page = uri.pathSegments[1];
        switch (portal) {
          case 'notice':
            _handleNotice(uri, page, ref, navigationNotifier);
            return;
          case 'vote':
            _handleVote(uri, page, longUrl, navigationNotifier, ref);
            return;
          case 'community':
            _handleCommunity(page, uri, navigationNotifier);
            return;
          case 'post':
            if (await _handlePost(uri, navigationNotifier)) return;
            break;
          case 'qna':
            if (await _handleQna(uri, navigationNotifier)) return;
            break;
        }
      }

      _handleStaticPages(uri, ref);
    } catch (e, s) {
      logger.e('딥링크 처리 중 오류:', error: e, stackTrace: s);
    }
  }

  // --- Portal handlers ---

  static void _handleNotice(
    Uri uri,
    String page,
    WidgetRef ref,
    NavigationInfo navigationNotifier,
  ) {
    try {
      final noticeId = int.parse(page);
      final targetPage = NoticeDetailPage(noticeId: noticeId);
      _pushToCurrentPortal(ref, navigationNotifier, targetPage,
          fallbackPortal: PortalType.vote, usePushKeepScreen: true);
    } catch (_) {}
  }

  static void _handleVote(
    Uri uri,
    String page,
    String longUrl,
    NavigationInfo navigationNotifier,
    WidgetRef ref,
  ) {
    Widget targetPage;
    switch (page) {
      case 'list':
        targetPage = const VoteListPage();
        break;
      case 'detail':
        if (uri.pathSegments.length >= 3) {
          final voteId = uri.pathSegments[2];
          final type = uri.queryParameters['type'];
          if (type == 'achieve') {
            targetPage = VoteDetailAchievePage(voteId: int.parse(voteId));
          } else {
            targetPage = VoteDetailPage(voteId: int.parse(voteId));
          }
        } else {
          logger.w('Invalid vote detail URL: $longUrl (missing voteId)');
          return;
        }
        break;
      default:
        return;
    }
    _pushToCurrentPortal(ref, navigationNotifier, targetPage,
        fallbackPortal: PortalType.vote);
  }

  static void _handleCommunity(
    String page,
    Uri uri,
    NavigationInfo navigationNotifier,
  ) {
    navigationNotifier.setPortal(PortalType.community);
    switch (page) {
      case 'home':
        navigationNotifier.setCurrentPage(const CommunityHomePage());
        break;
      case 'board_list':
        navigationNotifier.setCurrentPage(const BoardListPage());
        break;
      case 'board_detail':
        final artistId = uri.pathSegments[2];
        logger.i('artistId: $artistId');
        navigationNotifier.setCurrentPage(BoardHomePage(int.parse(artistId)));
        break;
      case 'fortune':
        logger.i('Fortune/Goonghap 기능이 임시로 비활성화되었습니다.');
        break;
      case 'compatibility':
      case 'goonghap':
        logger.i('Goonghap 기능이 임시로 비활성화되었습니다.');
        break;
    }
  }

  /// Returns `true` if navigation was handled successfully.
  static Future<bool> _handlePost(
    Uri uri,
    NavigationInfo navigationNotifier,
  ) async {
    if (uri.pathSegments.length < 2) return false;
    final postId = uri.pathSegments[1];
    if (postId.isEmpty) return false;

    final context = navigatorKey.currentContext;
    if (context == null) {
      logger.w('Navigator context가 없어 게시물 페이지를 열 수 없습니다');
      return true; // handled (even though failed)
    }

    _pushFullScreenPage(
      context,
      navigationNotifier,
      CommunityPostDetailScreen(postId: postId),
    );
    return true;
  }

  /// Returns `true` if navigation was handled successfully.
  static Future<bool> _handleQna(
    Uri uri,
    NavigationInfo navigationNotifier,
  ) async {
    if (uri.pathSegments.length < 2) return false;
    final questionIdStr = uri.pathSegments[1];
    if (questionIdStr.isEmpty) return false;

    try {
      final threadId = int.parse(questionIdStr);
      final repo = QnaRepository();
      final withMsgs = await repo.getQaThreadById(threadId);
      final context = navigatorKey.currentContext;
      if (context == null) {
        logger.w('Navigator context가 없어 QnA 페이지를 열 수 없습니다');
        return true;
      }
      _pushFullScreenPage(
        context,
        navigationNotifier,
        QnaThreadDetailPage(thread: withMsgs.thread, syncNavigation: false),
      );
      return true;
    } catch (e, s) {
      logger.e('QnA thread 로드 실패: $questionIdStr', error: e, stackTrace: s);
      return false;
    }
  }

  static void _handleStaticPages(Uri uri, WidgetRef ref) {
    if (uri.pathSegments.contains('terms')) {
      uri.pathSegments.contains('ko')
          ? const TermsScreen(language: 'ko')
          : const TermsScreen(language: 'en');
    } else if (uri.pathSegments.contains('privacy')) {
      uri.pathSegments.contains('ko')
          ? const PrivacyScreen(language: 'ko')
          : const PrivacyScreen(language: 'en');
    } else {
      try {
        final userInfoNotifier = ref.read(userInfoProvider.notifier);
        userInfoNotifier.getUserProfiles();
      } catch (e) {
        logger.e('getUserProfiles 호출 중 오류: $e');
      }
    }
  }

  // --- Navigation helpers ---

  /// Pushes [targetPage] into the current portal's page stack.
  /// If the current portal doesn't support direct page setting,
  /// switches to [fallbackPortal] and sets the page on the next frame.
  static void _pushToCurrentPortal(
    WidgetRef ref,
    NavigationInfo navigationNotifier,
    Widget targetPage, {
    required PortalType fallbackPortal,
    bool usePushKeepScreen = false,
  }) {
    final currentPortal = ref.read(navigationInfoProvider).portalType;
    if (currentPortal == PortalType.community) {
      navigationNotifier.setCommunityCurrentPage(targetPage);
    } else if (currentPortal == PortalType.pic) {
      navigationNotifier.setPicCurrentPage(targetPage);
    } else if (currentPortal == PortalType.novel) {
      navigationNotifier.setNovelCurrentPage(targetPage);
    } else {
      navigationNotifier.setPortal(fallbackPortal);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (usePushKeepScreen) {
          navigationNotifier.pushVotePageKeepScreen(targetPage);
        } else {
          navigationNotifier.setCurrentPage(targetPage);
        }
      });
    }
  }

  /// Pushes a full-screen page with bottom nav hidden during navigation.
  static void _pushFullScreenPage(
    BuildContext context,
    NavigationInfo navigationNotifier,
    Widget page,
  ) {
    navigationNotifier.setShowBottomNavigation(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => page))
          .whenComplete(() {
        navigationNotifier.setShowBottomNavigation(true);
      });
    });
  }
}
