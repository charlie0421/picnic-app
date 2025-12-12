import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/portal_menu_item.dart';
import 'package:picnic_lib/presentation/common/top/top_menu.dart';
import 'package:picnic_lib/presentation/common/top/top_right_notifications.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  Navigation? _previousNavigation;
  bool _initialized = false;
  late final NavigationInfo _navigationNotifier = ref.read(
    navigationInfoProvider.notifier,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      final currentNavigation = ref.read(navigationInfoProvider);
      _previousNavigation = currentNavigation;

      final nextNavigation = currentNavigation.copyWith(
        portalType: PortalType.community,
        showPortal: true,
        showTopMenu: true,
        showBottomNavigation: false,
      );

      _scheduleNavigationUpdate(nextNavigation);
    });
  }

  @override
  void dispose() {
    if (_previousNavigation != null) {
      _scheduleNavigationUpdate(_previousNavigation!);
    }
    super.dispose();
  }

  void _scheduleNavigationUpdate(Navigation navigation) {
    Future.microtask(() {
      _navigationNotifier.replaceState(navigation);
    });
  }

  PreferredSizeWidget _buildPortalAppBar(BuildContext context) {
    final userInfoState = ref.watch(userInfoProvider);
    final isAdmin = userInfoState.value?.isAdmin ?? false;
    final theme = Theme.of(context);
    final backgroundColor =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      leadingWidth: 48.w,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: foregroundColor),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            PortalMenuItem(portalType: PortalType.vote),
            PortalMenuItem(portalType: PortalType.goongHap),
            if (isSupabaseLoggedSafely && isAdmin) ...[
              PortalMenuItem(portalType: PortalType.pic),
              PortalMenuItem(portalType: PortalType.novel),
            ],
          ],
        ),
      ),
      actions: const [TopRightNotifications()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPortal = ref.watch(
      navigationInfoProvider.select((value) => value.showPortal),
    );
    final showTopMenu = ref.watch(
      navigationInfoProvider.select((value) => value.showTopMenu),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showPortal ? _buildPortalAppBar(context) : null,
      body: Column(
        children: [
          if (showTopMenu) const TopMenu(),
          Expanded(child: PostViewPage(widget.postId)),
        ],
      ),
    );
  }
}
