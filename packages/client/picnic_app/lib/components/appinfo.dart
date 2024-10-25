import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppInfo extends ConsumerWidget {
  const AppInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlatformInfoState = ref.watch(platformInfoProvider);

    return asyncPlatformInfoState.when(
      data: (platformInfo) {
        User? user = supabase.auth.currentUser;

        logger.d('user: $user');
        return ListView(
          children: [
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
