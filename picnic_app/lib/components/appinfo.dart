import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/main.dart';
import 'package:picnic_app/providers/platform_info_provider.dart';

class AppInfo extends ConsumerWidget {
  const AppInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlatformInfoState = ref.watch(platformInfoProvider);

    return asyncPlatformInfoState.when(
      data: (platformInfo) {
        return FutureBuilder(
          future: supabase
              .from('profiles')
              .select()
              .eq('id', "05e0896c-8891-49b8-99a1-ba6fd452e2dc")
              .single(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.error != null) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              logger.d('snapshot: ${snapshot.data}');
              final data = snapshot.data;
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
                      title: const Text('유저아이디'),
                      subtitle: Text(data['id'] ?? '--'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('유저이름'),
                      subtitle: Text(data['full_name'] ?? '--'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('프로필 이미지'),
                      subtitle: Text(data['avatar_url'] ?? '--'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('이메일'),
                      subtitle: Text(data['email'] ?? '--'),
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
