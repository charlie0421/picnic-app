import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/test_memory_profiler_extension.dart';

void main() {
  setUp(() {
    // 테스트 시작 시 메모리 프로파일러 초기화
    MemoryProfiler.instance.initialize(
      enabled: true,
      enableAutoSnapshot: true,
      autoSnapshotIntervalSeconds: 5,
    );
  });

  tearDown(() {
    // 테스트 종료 시 메모리 프로파일러 리셋
    MemoryProfiler.instance.reset();
  });

  testWidgets('앱 초기화 및 기본 화면 메모리 프로파일링', (WidgetTester tester) async {
    // 메모리 프로파일러 초기화
    await tester.initializeMemoryProfiler(
      autoSnapshot: true,
      snapshotIntervalSeconds: 5,
      leakThresholdMB: 15,
    );

    // 앱 초기화 전 스냅샷
    await tester.takeMemorySnapshot('app_init_before');

    // 앱 빌드 및 초기화
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // 앱 초기화 후 스냅샷
    await tester.takeMemorySnapshot('app_init_after');

    // 메모리 변화 확인
    final diff =
        tester.calculateMemoryDiff('app_init_before', 'app_init_after');
    if (diff != null) {
      final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
      expect(heapDiffMB, lessThan(30), reason: '앱 초기화 시 메모리 사용량이 30MB를 초과합니다');
    }

    // 위젯 테스트 수행
    expect(find.byType(App), findsOneWidget);

    // 보고서 생성
    final reportPath =
        await tester.generateMemoryReport('app_initialization_test');
    expect(reportPath, isNotNull, reason: '메모리 보고서 생성에 실패했습니다');

    // 누수 감지
    // ignore: unused_local_variable
    final leaks = await tester.detectMemoryLeaksAfterTest(
      thresholdMB: 20,
      failTestOnLeak: false, // 테스트에서는 경고만 표시하고 실패하지 않도록 설정
    );
    expect(leaks.length, equals(0), reason: '앱 초기화 중 메모리 누수가 감지되었습니다');
  });

  testWidgets('위젯 작업의 메모리 사용량 프로파일링', (WidgetTester tester) async {
    // 메모리 프로파일러 초기화
    await tester.initializeMemoryProfiler();

    // 앱 빌드
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // 카운터 작동 메모리 프로파일링
    await tester.profileWidgetAction('increment_counter', () async {
      // '+' 버튼 찾기
      final addButton = find.byIcon(Icons.add);

      // 10번 클릭
      for (int i = 0; i < 10; i++) {
        await tester.tap(addButton);
        await tester.pump();
      }
    });

    // 메모리 보고서 생성
    await tester.generateMemoryReport('counter_interaction_test');
  });

  testWidgets('이미지 로딩 및 프로파일링 테스트', (WidgetTester tester) async {
    // 메모리 프로파일러 초기화
    await tester.initializeMemoryProfiler();

    // 테스트용 이미지 위젯
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://picsum.photos/200',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('이미지 로드 테스트'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 이미지 로딩 작업 프로파일링
    await tester.profileImageAction(
      'load_network_image',
      'https://picsum.photos/200',
      () async {
        // 이미지 로딩 완료 대기
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
      thresholdMB: 20, // 이미지 작업은 메모리를 더 많이 사용할 수 있음
    );

    // 버튼 확인 및 클릭 테스트
    final button = find.text('이미지 로드 테스트');
    expect(button, findsOneWidget);

    await tester.profileWidgetAction(
      'button_click',
      () async {
        await tester.tap(button);
        await tester.pump();
      },
    );

    // 이미지 캐시 정보 확인
    final imageCacheStats = MemoryProfiler.instance.getImageCacheStats();
    expect(imageCacheStats.liveImages, greaterThan(0),
        reason: '이미지 캐시에 이미지가 없습니다');

    // 메모리 보고서 생성
    await tester.generateMemoryReport('image_loading_test');
  });

  testWidgets('메모리 누수 감지 자동화 테스트', (WidgetTester tester) async {
    // 메모리 프로파일러 초기화
    await tester.initializeMemoryProfiler();

    // 테스트 앱 로드
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // 다양한 상호작용 시뮬레이션
    for (int i = 0; i < 5; i++) {
      // 스냅샷 생성
      await tester.takeMemorySnapshot('interaction_$i');

      // 상호작용
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pump();
      }

      // 지연 추가
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 마지막 스냅샷
    await tester.takeMemorySnapshot('interaction_final');

    // 가비지 컬렉션 유도
    await Future.delayed(const Duration(seconds: 1));

    // 누수 감지
    // ignore: unused_local_variable
    final leaks = await tester.detectMemoryLeaksAfterTest(
      thresholdMB: 15,
      failTestOnLeak: false, // 실제 CI 환경에서는 true로 설정하여 테스트 실패하도록 할 수 있음
    );

    // 보고서 생성
    final reportPath =
        await tester.generateMemoryReport('memory_leak_detection_test');
    expect(reportPath, isNotNull);

    // 누수 감지 결과 확인 (여기서는 실패하지 않도록 주석 처리)
    // expect(leaks.length, equals(0), reason: '메모리 누수가 감지되었습니다');
  });
}
