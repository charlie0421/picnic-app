import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

class TopRightNotifications extends ConsumerWidget {
  const TopRightNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoState = ref.watch(userInfoProvider);
    final isAdmin = userInfoState.maybeWhen(
      data: (u) => (u?.isAdmin ?? false),
      orElse: () => false,
    );

    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final count = unreadAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    Widget bell = const Icon(Icons.notifications);
    if (count > 0) {
      bell = Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return IconButton(
      icon: bell,
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      },
      tooltip: '알림',
    );
  }
}
