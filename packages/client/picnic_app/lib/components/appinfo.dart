import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/providers/my_profile_provider.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';

class AppInfo extends ConsumerWidget {
  const AppInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlatformInfoState = ref.watch(platformInfoProvider);
    final asyncProfileState = ref.watch(asyncMyProfileProvider);

    return asyncPlatformInfoState.when(
      data: (platformInfo) {
        return ListView(
          children: [
            const Align(
                alignment: Alignment.center,
                child: Text('개발 및 커뮤니케이션용 임시 화면입니다.')),
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
                subtitle: Text(asyncProfileState.value?.nickname ?? '--'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('이메일'),
                subtitle: Text(asyncProfileState.value?.email ?? '--'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
