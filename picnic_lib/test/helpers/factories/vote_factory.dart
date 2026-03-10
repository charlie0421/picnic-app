import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';

/// 투표 관련 모델의 테스트 팩토리 클래스
class VoteFactory {
  /// 기본 VoteModel 생성
  static VoteModel create({
    int id = 1,
    Map<String, dynamic> title = const {'ko': '테스트 투표', 'en': 'Test Vote'},
    String? voteCategory = 'birthday',
    String? mainImage,
    String? waitImage,
    String? resultImage,
    String? voteContent,
    List<VoteItemModel>? voteItem,
    DateTime? createdAt,
    DateTime? visibleAt,
    DateTime? stopAt,
    DateTime? startAt,
    bool? isEnded = false,
    bool? isUpcoming = false,
    bool? isPartnership = false,
    String? partner,
    List<RewardModel>? reward,
  }) {
    final now = DateTime.now();
    return VoteModel(
      id: id,
      title: title,
      voteCategory: voteCategory,
      mainImage: mainImage,
      waitImage: waitImage,
      resultImage: resultImage,
      voteContent: voteContent,
      voteItem: voteItem ?? [],
      createdAt: createdAt ?? now,
      visibleAt: visibleAt ?? now.subtract(const Duration(days: 1)),
      stopAt: stopAt ?? now.add(const Duration(days: 7)),
      startAt: startAt ?? now.subtract(const Duration(hours: 1)),
      isEnded: isEnded,
      isUpcoming: isUpcoming,
      isPartnership: isPartnership,
      partner: partner,
      reward: reward ?? [],
    );
  }

  /// 종료된 투표 생성
  static VoteModel createEnded({
    int id = 100,
    Map<String, dynamic> title = const {'ko': '종료된 투표', 'en': 'Ended Vote'},
  }) {
    final now = DateTime.now();
    return create(
      id: id,
      title: title,
      isEnded: true,
      startAt: now.subtract(const Duration(days: 14)),
      stopAt: now.subtract(const Duration(days: 1)),
    );
  }

  /// 예정된 투표 생성
  static VoteModel createUpcoming({
    int id = 200,
    Map<String, dynamic> title = const {'ko': '예정 투표', 'en': 'Upcoming Vote'},
  }) {
    final now = DateTime.now();
    return create(
      id: id,
      title: title,
      isUpcoming: true,
      startAt: now.add(const Duration(days: 1)),
      stopAt: now.add(const Duration(days: 14)),
    );
  }
}

/// VoteItemModel 테스트 팩토리
class VoteItemFactory {
  /// 기본 VoteItemModel 생성
  static VoteItemModel create({
    int id = 1,
    int? voteTotal = 100,
    int? starCandyTotal = 50,
    int? starCandyBonusTotal = 10,
    int voteId = 1,
    ArtistModel? artist,
    ArtistGroupModel? artistGroup,
  }) {
    return VoteItemModel(
      id: id,
      voteTotal: voteTotal,
      starCandyTotal: starCandyTotal,
      starCandyBonusTotal: starCandyBonusTotal,
      voteId: voteId,
      artist: artist,
      artistGroup: artistGroup,
    );
  }
}

/// VoteItemRequest 테스트 팩토리
class VoteItemRequestFactory {
  /// 기본 VoteItemRequest 생성
  static VoteItemRequest create({
    String id = 'test-request-id-001',
    int voteId = 1,
    String status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return VoteItemRequest(
      id: id,
      voteId: voteId,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}

/// VoteItemRequestUser 테스트 팩토리
class VoteItemRequestUserFactory {
  /// 기본 VoteItemRequestUser 생성
  static VoteItemRequestUser create({
    String id = 'test-request-user-id-001',
    int voteId = 1,
    String userId = 'test-user-id-001',
    int artistId = 1,
    String status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
    ArtistModel? artist,
  }) {
    final now = DateTime.now();
    return VoteItemRequestUser(
      id: id,
      voteId: voteId,
      userId: userId,
      artistId: artistId,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      artist: artist,
    );
  }
}

/// VoteAchieve 테스트 팩토리
class VoteAchieveFactory {
  /// 기본 VoteAchieve 생성
  static VoteAchieve create({
    int id = 1,
    int voteId = 1,
    int rewardId = 1,
    int order = 1,
    int amount = 100,
    RewardModel? reward,
    VoteModel? vote,
  }) {
    return VoteAchieve(
      id: id,
      voteId: voteId,
      rewardId: rewardId,
      order: order,
      amount: amount,
      reward: reward ?? RewardFactory.create(id: rewardId),
      vote: vote ?? VoteFactory.create(id: voteId),
    );
  }
}

/// RewardModel 테스트 팩토리
class RewardFactory {
  /// 기본 RewardModel 생성
  static RewardModel create({
    int id = 1,
    Map<String, dynamic>? title,
    String? thumbnail,
    List<String>? overviewImages,
    Map<String, dynamic>? location,
    Map<String, dynamic>? sizeGuide,
    List<String>? sizeGuideImages,
  }) {
    return RewardModel(
      id: id,
      title: title ?? const {'ko': '테스트 보상', 'en': 'Test Reward'},
      thumbnail: thumbnail,
      overviewImages: overviewImages,
      location: location,
      sizeGuide: sizeGuide,
      sizeGuideImages: sizeGuideImages,
    );
  }
}
