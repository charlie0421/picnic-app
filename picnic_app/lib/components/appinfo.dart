import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class AppInfo extends ConsumerWidget {
  const AppInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlatformInfoState = ref.watch(platformInfoProvider);
    final navagationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    return asyncPlatformInfoState.when(
      data: (platformInfo) {
        User? user = Supabase.instance.client.auth.currentUser;

        logger.d('user: $user');
        return ListView(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.width / 2,
              child: CachedNetworkImage(
                imageUrl: user?.userMetadata?['avatar_url'] ?? '',
                placeholder: (context, url) => buildPlaceholderImage(),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('앱버전'),
                subtitle: Text(
                    '${platformInfo.version}(${platformInfo.buildNumber})'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('유저이름'),
                subtitle: Text(user?.userMetadata?['full_name'] ?? '--'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('이메일'),
                subtitle: Text(user?.email ?? '--'),
              ),
            ),
            if (Supabase.instance.client.isLogged == true)
              ElevatedButton(
                onPressed: () {
                  Supabase.instance.client.auth.signOut();
                  ref.read(loginedProvider.notifier).setLogined(false);
                  final navigationInfoNotifier =
                      ref.read(navigationInfoProvider.notifier);
                  navigationInfoNotifier.setCurrentPage(const LoginScreen());
                },
                child: const Text('로그아웃'),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () {
                ref.refresh(platformInfoProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
