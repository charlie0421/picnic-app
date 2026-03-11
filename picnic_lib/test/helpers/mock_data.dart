import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// 테스트용 Mock 데이터 팩토리
class MockData {
  // ========== Navigation ==========
  static Navigation navigation({
    PortalType portalType = PortalType.vote,
    bool showPortal = true,
    bool showTopMenu = true,
    bool showBottomNavigation = true,
    int voteBottomNavigationIndex = 0,
  }) {
    return Navigation(
      portalType: portalType,
      showPortal: showPortal,
      showTopMenu: showTopMenu,
      showBottomNavigation: showBottomNavigation,
      voteBottomNavigationIndex: voteBottomNavigationIndex,
    );
  }

  // ========== User ==========
  static UserProfilesModel userProfile({
    String id = 'test-user-id',
    String? nickname = 'TestUser',
    String? avatarUrl,
    int starCandy = 100,
    int starCandyBonus = 10,
    int jmaCandy = 50,
    bool isAdmin = false,
  }) {
    return UserProfilesModel(
      id: id,
      nickname: nickname,
      avatarUrl: avatarUrl,
      isAdmin: isAdmin,
      starCandy: starCandy,
      starCandyBonus: starCandyBonus,
      jmaCandy: jmaCandy,
    );
  }

  static UserProfilesModel? nullUser() => null;

  // ========== Settings ==========
  static Setting setting({
    ThemeMode themeMode = ThemeMode.system,
    String language = 'ko',
    String area = 'all',
    bool postAnonymousMode = false,
  }) {
    return Setting(
      themeMode: themeMode,
      language: language,
      area: area,
      postAnonymousMode: postAnonymousMode,
    );
  }

  // ========== Artist ==========
  static ArtistModel artist({
    int id = 1,
    String nameKo = '지민',
    String nameEn = 'Jimin',
    ArtistGroupModel? artistGroup,
  }) {
    return ArtistModel.fromJson({
      'id': id,
      'name': {'ko': nameKo, 'en': nameEn},
      if (artistGroup != null) 'artist_group': artistGroup.toJson(),
    });
  }

  static ArtistGroupModel artistGroup({
    int id = 1,
    String nameKo = 'BTS',
    String nameEn = 'BTS',
    String? image,
  }) {
    return ArtistGroupModel.fromJson({
      'id': id,
      'name': {'ko': nameKo, 'en': nameEn},
      'image': image,
    });
  }

  // ========== Vote ==========
  static VoteModel vote({
    int id = 1,
    String titleKo = '테스트 투표',
    String titleEn = 'Test Vote',
    String? voteCategory = 'birthday',
    DateTime? startAt,
    DateTime? stopAt,
    bool isEnded = false,
    bool isUpcoming = false,
  }) {
    return VoteModel.fromJson({
      'id': id,
      'title': {'ko': titleKo, 'en': titleEn},
      'vote_category': voteCategory,
      'main_image': null,
      'wait_image': null,
      'result_image': null,
      'vote_content': null,
      'vote_item': null,
      'created_at': null,
      'visible_at': null,
      'start_at': startAt?.toIso8601String() ??
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'stop_at': stopAt?.toIso8601String() ??
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'is_ended': isEnded,
      'is_upcoming': isUpcoming,
      'is_partnership': false,
      'partner': null,
      'reward': null,
    });
  }

  static VoteItemModel voteItem({
    int id = 1,
    int voteTotal = 1000,
    int voteId = 1,
    ArtistModel? artist,
  }) {
    return VoteItemModel.fromJson({
      'id': id,
      'vote_total': voteTotal,
      'vote_id': voteId,
      'artist': artist?.toJson() ?? MockData.artist().toJson(),
      'artist_group': null,
    });
  }

  // ========== Banner ==========
  static BannerModel banner({
    int id = 1,
    String titleKo = '배너',
    String thumbnail = 'https://example.com/thumb.jpg',
    int duration = 3000,
  }) {
    return BannerModel.fromJson({
      'id': id,
      'title': {'ko': titleKo},
      'thumbnail': thumbnail,
      'image': {'ko': 'https://example.com/img.jpg'},
      'duration': duration,
      'link': null,
    });
  }

  // ========== Celeb ==========
  static CelebModel celeb({
    int id = 1,
    String nameKo = '지민',
    String nameEn = 'Jimin',
  }) {
    return CelebModel.fromJson({
      'id': id,
      'name_ko': nameKo,
      'name_en': nameEn,
    });
  }

  // ========== Reward ==========
  static RewardModel reward({
    int id = 1,
    String titleKo = '포토카드',
  }) {
    return RewardModel.fromJson({
      'id': id,
      'title': {'ko': titleKo},
    });
  }

  // ========== Community ==========
  static CommunityState communityState() {
    return const CommunityState();
  }

  // ========== MediaQuery ==========
  static MediaQueryData mediaQueryData({
    double width = 375,
    double height = 812,
  }) {
    return MediaQueryData(
      size: Size(width, height),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      devicePixelRatio: 3.0,
    );
  }
}
