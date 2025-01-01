import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/presentation/common/avatar_container.dart';
import 'package:picnic_app/presentation/common/picnic_list_item.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/presentation/pages/community/community_my_comment.dart';
import 'package:picnic_app/presentation/pages/community/community_my_scraps.dart';
import 'package:picnic_app/presentation/pages/community/community_my_writen.dart';
import 'package:picnic_app/presentation/pages/community/compatibility_list_page.dart';
import 'package:picnic_app/presentation/providers/app_setting_provider.dart';
import 'package:picnic_app/presentation/providers/navigation_provider.dart';
import 'package:picnic_app/presentation/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';

class CommunityMyPage extends ConsumerStatefulWidget {
  const CommunityMyPage({super.key});

  @override
  ConsumerState<CommunityMyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<CommunityMyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfoState = ref.watch(userInfoProvider);
    final postAnonymousMode = ref
        .watch(appSettingProvider.select((value) => value.postAnonymousMode));
    final appSettingNotifier = ref.read(appSettingProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          postAnonymousMode
              ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  const NoAvatar(width: 60, height: 60, borderRadius: 30),
                  SizedBox(width: 16.cw),
                  Text(
                    S.of(context).anonymous,
                    style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                  )
                ])
              : userInfoState.when(
                  data: (data) {
                    if (data == null) {
                      return const SizedBox();
                    }
                    return Row(
                      children: [
                        ProfileImageContainer(
                          avatarUrl: data.avatarUrl,
                          borderRadius: 30,
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          data.nickname ?? '',
                          style:
                              getTextStyle(AppTypo.title18B, AppColors.grey900),
                        )
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('error: $error'),
                ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).anonymous_mode,
                  style: getTextStyle(AppTypo.body16M)),
              Switch(
                  inactiveTrackColor: AppColors.grey300,
                  inactiveThumbColor: AppColors.grey00,
                  value: postAnonymousMode,
                  onChanged: (value) =>
                      appSettingNotifier.setPostAnonymousMode(value)),
            ],
          ),
          const Divider(color: AppColors.grey200),
          PicnicListItem(
            leading: S.of(context).post_my_written_post,
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            onTap: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(const CommunityMyWriten());
            },
          ),
          PicnicListItem(
            leading: S.of(context).post_my_written_scrap,
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            onTap: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(const CommunityMyScraps());
            },
          ),
          PicnicListItem(
            leading: S.of(context).post_my_written_reply,
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            onTap: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(const CommunityMyComment());
            },
          ),
          PicnicListItem(
            leading: S.of(context).post_my_compatibilities,
            assetPath: 'assets/icons/arrow_right_style=line.svg',
            onTap: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(const CompatibilityHistoryPage());
            },
          ),
        ],
      ),
    );
  }
}
