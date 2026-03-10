import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/application_count_tag.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/common_artist_widget.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/ui/style.dart';

void main() {
  setUpAll(() {
    // AppColors의 Environment 의존 필드를 테스트용 기본값으로 초기화
    AppColors.primary500 = const Color(0xFF6200EE);
    AppColors.secondary500 = const Color(0xFF03DAC6);
    AppColors.sub500 = const Color(0xFF018786);
    AppColors.point500 = const Color(0xFFBB86FC);
    AppColors.point900 = const Color(0xFF3700B3);
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: child,
          ),
        );
      },
    );
  }

  group('ApplicationCountTag 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ApplicationCountTag(applicationCount: 100),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationCountTag), findsOneWidget);
    });

    testWidgets('신청 수가 올바르게 표시되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ApplicationCountTag(applicationCount: 1234),
        ),
      );
      await tester.pumpAndSettle();

      // ArtistNameUtils.formatNumber로 포맷된 숫자가 표시되는지 확인
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('0 신청 수가 표시되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ApplicationCountTag(applicationCount: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('투표 아이콘이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ApplicationCountTag(applicationCount: 50),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
    });

    testWidgets('Row 위젯으로 구성되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ApplicationCountTag(applicationCount: 10),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
    });
  });

  group('CommonArtistWidget 위젯 테스트', () {
    testWidgets('아티스트 없이 이름만으로 렌더링되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CommonArtistWidget(
            artist: null,
            artistName: '테스트 아티스트',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommonArtistWidget), findsOneWidget);
      expect(find.text('테스트 아티스트'), findsOneWidget);
    });

    testWidgets('빈 아티스트 이름일 때 기본값이 표시되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CommonArtistWidget(
            artist: null,
            artistName: '',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommonArtistWidget), findsOneWidget);
      // 빈 이름일 때 '알 수 없는 아티스트'가 표시됨
      expect(find.text('알 수 없는 아티스트'), findsOneWidget);
    });

    testWidgets('아티스트 이미지가 없을 때 기본 아이콘이 표시되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CommonArtistWidget(
            artist: null,
            artistName: '테스트',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // artist가 null이면 기본 person 아이콘이 표시됨
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('trailing 위젯이 표시되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CommonArtistWidget(
            artist: null,
            artistName: '테스트 아티스트',
            trailing: Icon(Icons.check),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('그룹 이름이 표시되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CommonArtistWidget(
            artist: null,
            artistName: '멤버 이름',
            groupName: '그룹 이름',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('멤버 이름'), findsOneWidget);
      expect(find.text('그룹 이름'), findsOneWidget);
    });
  });

  group('ArtistNameUtils 유틸리티 테스트', () {
    test('formatNumber가 3자리 콤마를 올바르게 적용하는지 확인', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(999), '999');
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(1234567), '1,234,567');
      expect(ArtistNameUtils.formatNumber(100), '100');
    });
  });

  group('ArtistApplicationInfo 모델 테스트', () {
    test('ArtistApplicationInfo가 정상적으로 생성되는지 확인', () {
      const info = ArtistApplicationInfo(
        artistName: '테스트',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      expect(info.artistName, '테스트');
      expect(info.applicationCount, 5);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, false);
      expect(info.isSubmitting, false);
    });

    test('ArtistApplicationInfo의 copyWith가 정상 동작하는지 확인', () {
      const info = ArtistApplicationInfo(
        artistName: '테스트',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(
        applicationCount: 10,
        isSubmitting: true,
      );

      expect(updated.artistName, '테스트');
      expect(updated.applicationCount, 10);
      expect(updated.isSubmitting, true);
    });
  });

  group('UserApplicationInfo 모델 테스트', () {
    test('UserApplicationInfo가 정상적으로 생성되는지 확인', () {
      const info = UserApplicationInfo(
        id: 'test-id',
        artistName: '아티스트',
        status: 'approved',
        applicationCount: 100,
      );

      expect(info.id, 'test-id');
      expect(info.artistName, '아티스트');
      expect(info.status, 'approved');
      expect(info.applicationCount, 100);
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('UserApplicationInfo에 그룹 이름을 포함할 수 있는지 확인', () {
      const info = UserApplicationInfo(
        id: 'test-id',
        artistName: '멤버',
        groupName: '그룹',
        status: 'pending',
        applicationCount: 50,
      );

      expect(info.groupName, '그룹');
    });
  });
}
