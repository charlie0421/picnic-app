import 'package:picnic_app/enums.dart';

extension PortalTypeExtension on PortalType {
  String get stringValue {
    switch (this) {
      case PortalType.vote:
        return 'vote';
      case PortalType.pic:
        return 'pic';
      case PortalType.community:
        return 'community';
      case PortalType.novel:
        return 'novel';
      case PortalType.mypage:
        return 'mypage';
    }
  }

  static PortalType fromString(String value) {
    switch (value) {
      case 'vote':
        return PortalType.vote;
      case 'pic':
        return PortalType.pic;
      case 'community':
        return PortalType.community;
      case 'novel':
        return PortalType.novel;
      case 'mypage':
        return PortalType.mypage;
      default:
        throw Exception('Unknown portal type string: $value');
    }
  }
}
