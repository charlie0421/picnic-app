import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';

/// 아티스트 모델 테스트 팩토리 클래스
class ArtistFactory {
  /// 기본 ArtistModel 생성
  static ArtistModel create({
    int id = 1,
    Map<String, dynamic> name = const {'ko': '테스트 아티스트', 'en': 'Test Artist'},
    int? yy = 2000,
    int? mm = 1,
    int? dd = 15,
    DateTime? birthDateRaw,
    String? gender = 'F',
    ArtistGroupModel? artistGroup,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isBookmarked = false,
  }) {
    return ArtistModel(
      id: id,
      name: name,
      yy: yy,
      mm: mm,
      dd: dd,
      birthDateRaw: birthDateRaw,
      gender: gender,
      artistGroup: artistGroup,
      image: image,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      isBookmarked: isBookmarked,
    );
  }

  /// 삭제된 아티스트 생성
  static ArtistModel createDeleted({
    int id = 99,
    Map<String, dynamic> name = const {'ko': '삭제된 아티스트', 'en': 'Deleted Artist'},
  }) {
    return create(
      id: id,
      name: name,
      deletedAt: DateTime.now(),
    );
  }

  /// 그룹에 속한 아티스트 생성
  static ArtistModel createWithGroup({
    int id = 1,
    Map<String, dynamic> name = const {'ko': '멤버', 'en': 'Member'},
    ArtistGroupModel? group,
  }) {
    return create(
      id: id,
      name: name,
      artistGroup: group ?? ArtistGroupFactory.create(),
    );
  }

  /// 북마크된 아티스트 생성
  static ArtistModel createBookmarked({
    int id = 1,
    Map<String, dynamic> name = const {'ko': '북마크 아티스트', 'en': 'Bookmarked Artist'},
  }) {
    return create(
      id: id,
      name: name,
      isBookmarked: true,
    );
  }
}

/// 아티스트 그룹 모델 테스트 팩토리 클래스
class ArtistGroupFactory {
  /// 기본 ArtistGroupModel 생성
  static ArtistGroupModel create({
    int id = 1,
    Map<String, dynamic> name = const {'ko': '테스트 그룹', 'en': 'Test Group'},
    String? image,
  }) {
    return ArtistGroupModel(
      id: id,
      name: name,
      image: image,
    );
  }
}
