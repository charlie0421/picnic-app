import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';

void main() {
  group('RewardDialogConstants', () {
    test('이미지 반경 확인', () {
      expect(RewardDialogConstants.imageRadius, equals(24));
    });

    test('상단 섹션 높이 확인', () {
      expect(RewardDialogConstants.topSectionHeight, equals(400));
    });

    test('닫기 버튼 크기 확인', () {
      expect(RewardDialogConstants.closeButtonSize, equals(48));
    });

    test('전환 지속시간 확인', () {
      expect(
        RewardDialogConstants.transitionDuration,
        equals(const Duration(milliseconds: 300)),
      );
    });
  });

  group('RewardType enum', () {
    test('3개의 값이 정의됨', () {
      expect(RewardType.values.length, equals(3));
    });

    test('overview, location, sizeGuide 값 존재', () {
      expect(RewardType.overview, isNotNull);
      expect(RewardType.location, isNotNull);
      expect(RewardType.sizeGuide, isNotNull);
    });

    test('index 순서 확인', () {
      expect(RewardType.overview.index, equals(0));
      expect(RewardType.location.index, equals(1));
      expect(RewardType.sizeGuide.index, equals(2));
    });
  });
}
