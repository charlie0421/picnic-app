// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/data_lazy_loader.dart';
import 'package:picnic_lib/core/utils/lazy_loading_manager.dart';
import 'package:picnic_lib/core/utils/widget_lazy_loader.dart';
import 'package:picnic_lib/presentation/widgets/lazy_list_view.dart';

/// 지연 로딩 시스템을 테스트하는 테스트 파일
///
/// LazyLoadingManager의 기능과 성능을 검증합니다.
void main() {
  group('LazyLoadingManager 테스트', () {
    late LazyLoadingManager lazyLoadingManager;

    setUp(() {
      lazyLoadingManager = LazyLoadingManager();
      lazyLoadingManager.reset(); // 각 테스트 전에 상태 초기화
    });

    tearDown(() {
      lazyLoadingManager.reset(); // 각 테스트 후에 상태 정리
    });

    test('LazyLoadingManager 초기화 테스트', () {
      // Given
      expect(lazyLoadingManager.getServiceStatus(), isEmpty);

      // When
      lazyLoadingManager.initialize();

      // Then
      // 초기화 후에도 서비스는 아직 로드되지 않아야 함
      expect(lazyLoadingManager.getServiceStatus(), isEmpty);
    });

    test('백그라운드 초기화 스케줄링 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      await lazyLoadingManager.startBackgroundInitialization(
        enableMemoryProfiler: false,
      );

      // Then
      // 백그라운드 초기화가 시작되었지만 즉시 완료되지는 않을 수 있음
      // 잠시 대기 후 상태 확인
      await Future.delayed(const Duration(milliseconds: 100));

      final serviceStatus = lazyLoadingManager.getServiceStatus();
      expect(serviceStatus, isNotEmpty);
    });

    test('특정 서비스 로딩 대기 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      final future = lazyLoadingManager.waitForService('image_services');
      await lazyLoadingManager.forceLoadService('image_services');
      await future;

      // Then
      expect(lazyLoadingManager.isServiceLoaded('image_services'), isTrue);
    });

    test('서비스 로딩 상태 확인 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      await lazyLoadingManager.forceLoadService('network_services');

      // Then
      expect(lazyLoadingManager.isServiceLoaded('network_services'), isTrue);
      expect(lazyLoadingManager.isServiceLoaded('mobile_services'), isFalse);
    });

    test('모든 서비스 로딩 완료 대기 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      final startTime = DateTime.now();

      // 백그라운드 초기화 시작
      unawaited(lazyLoadingManager.startBackgroundInitialization(
        enableMemoryProfiler: false,
      ));

      // 모든 서비스 완료 대기
      await lazyLoadingManager.waitForAllServices();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Then
      final serviceStatus = lazyLoadingManager.getServiceStatus();
      expect(serviceStatus.values.every((loaded) => loaded), isTrue);

      print('모든 서비스 로딩 완료 시간: ${duration.inMilliseconds}ms');
      print('로드된 서비스: ${serviceStatus.keys.toList()}');
    });

    test('중복 서비스 로딩 방지 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      await lazyLoadingManager.forceLoadService('image_services');
      final firstLoadTime = DateTime.now();

      await lazyLoadingManager.forceLoadService('image_services'); // 중복 로딩 시도
      final secondLoadTime = DateTime.now();

      // Then
      expect(lazyLoadingManager.isServiceLoaded('image_services'), isTrue);

      // 두 번째 로딩은 즉시 완료되어야 함 (이미 로드됨)
      final duplicateLoadDuration = secondLoadTime.difference(firstLoadTime);
      expect(duplicateLoadDuration.inMilliseconds, lessThan(50));
    });

    test('서비스 로딩 실패 처리 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When & Then
      // 존재하지 않는 서비스 로딩 시도
      await lazyLoadingManager.forceLoadService('non_existent_service');

      // 실패해도 앱이 크래시되지 않아야 함
      expect(
          lazyLoadingManager.isServiceLoaded('non_existent_service'), isFalse);
    });

    test('성능 측정 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When
      final startTime = DateTime.now();

      await lazyLoadingManager.startBackgroundInitialization(
        enableMemoryProfiler: false,
      );

      // 이미지 서비스만 대기 (가장 빠르게 로드되는 서비스)
      await lazyLoadingManager.waitForService('image_services');

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Then
      expect(lazyLoadingManager.isServiceLoaded('image_services'), isTrue);

      print('이미지 서비스 로딩 시간: ${duration.inMilliseconds}ms');

      // 이미지 서비스는 1초 이내에 로드되어야 함
      expect(duration.inMilliseconds, lessThan(1000));
    });

    test('메모리 프로파일러 조건부 로딩 테스트', () async {
      // Given
      lazyLoadingManager.initialize();

      // When - 메모리 프로파일러 비활성화
      await lazyLoadingManager.startBackgroundInitialization(
        enableMemoryProfiler: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Then
      final serviceStatus = lazyLoadingManager.getServiceStatus();

      // 디버그 모드가 아닌 경우 메모리 프로파일링 서비스가 로드되지 않을 수 있음
      print('서비스 상태 (메모리 프로파일러 비활성화): $serviceStatus');
    });
  });

  group('LazyLoadingManager 통합 테스트', () {
    test('실제 앱 시나리오 시뮬레이션', () async {
      // Given
      final lazyManager = LazyLoadingManager();
      lazyManager.initialize();

      // When - 앱 시작 시나리오
      print('📱 앱 시작 시뮬레이션...');

      final appStartTime = DateTime.now();

      // 백그라운드 서비스 초기화 시작
      unawaited(lazyManager.startBackgroundInitialization());

      // 사용자가 첫 화면을 보는 시점 (즉시)
      final firstScreenTime = DateTime.now();
      print(
          '첫 화면 표시 시간: ${firstScreenTime.difference(appStartTime).inMilliseconds}ms');

      // 사용자가 이미지가 포함된 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));
      await lazyManager.waitForService('image_services');

      final imageReadyTime = DateTime.now();
      print(
          '이미지 서비스 준비 시간: ${imageReadyTime.difference(appStartTime).inMilliseconds}ms');

      // 사용자가 설정 화면으로 이동 (모바일 서비스 필요)
      await Future.delayed(const Duration(milliseconds: 1000));
      await lazyManager.waitForService('mobile_services');

      final settingsReadyTime = DateTime.now();
      print(
          '설정 화면 준비 시간: ${settingsReadyTime.difference(appStartTime).inMilliseconds}ms');

      // Then
      final finalServiceStatus = lazyManager.getServiceStatus();
      print('최종 서비스 상태: $finalServiceStatus');

      expect(lazyManager.isServiceLoaded('image_services'), isTrue);
      expect(lazyManager.isServiceLoaded('mobile_services'), isTrue);
    });
  });

  group('위젯 지연 로딩 테스트', () {
    late WidgetLazyLoader widgetLoader;

    setUp(() {
      widgetLoader = WidgetLazyLoader();
    });

    tearDown(() {
      widgetLoader.dispose();
    });

    test('위젯 등록 및 로드', () {
      // Given
      const widgetId = 'test_widget';
      Widget testWidget = const Text('Test Widget');

      // When
      widgetLoader.registerLazyWidget(
        id: widgetId,
        builder: () => testWidget,
        priority: LazyLoadPriority.high,
      );

      final loadedWidget = widgetLoader.loadWidget(widgetId);

      // Then
      expect(widgetLoader.isWidgetLoaded(widgetId), isTrue);
      expect(loadedWidget, isA<Text>());
    });

    test('위젯 상태 추적', () {
      // Given
      widgetLoader.registerLazyWidget(
        id: 'widget1',
        builder: () => const Text('Widget 1'),
      );
      widgetLoader.registerLazyWidget(
        id: 'widget2',
        builder: () => const Text('Widget 2'),
      );

      // When
      widgetLoader.loadWidget('widget1');
      final status = widgetLoader.getStatus();

      // Then
      expect(status['registered_widgets'], equals(2));
      expect(status['loaded_widgets'], equals(1));
    });
  });

  group('데이터 지연 로딩 테스트', () {
    late DataLazyLoader dataLoader;

    setUp(() {
      dataLoader = DataLazyLoader();
    });

    tearDown(() {
      dataLoader.dispose();
    });

    test('데이터 등록 및 로드', () async {
      // Given
      const dataId = 'test_data';
      const testData = 'Test Data';

      dataLoader.registerLazyData<String>(
        id: dataId,
        loader: () async => testData,
        priority: DataLoadPriority.high,
      );

      // When
      final loadedData = await dataLoader.loadData<String>(dataId);

      // Then
      expect(loadedData, equals(testData));
      expect(dataLoader.isDataLoaded(dataId), isTrue);
    });

    test('데이터 캐싱', () async {
      // Given
      const dataId = 'cached_data';
      int loadCount = 0;

      dataLoader.registerLazyData<String>(
        id: dataId,
        loader: () async {
          loadCount++;
          return 'Data $loadCount';
        },
        cacheResult: true,
      );

      // When
      final firstLoad = await dataLoader.loadData<String>(dataId);
      final secondLoad = await dataLoader.loadData<String>(dataId);

      // Then
      expect(firstLoad, equals('Data 1'));
      expect(secondLoad, equals('Data 1')); // 캐시된 데이터
      expect(loadCount, equals(1)); // 한 번만 로드됨
    });
  });

  group('LazyListView 테스트', () {
    testWidgets('기본 리스트 렌더링', (WidgetTester tester) async {
      // Given
      final items = List.generate(10, (index) => 'Item $index');

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String>(
              items: items,
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
              enableLazyLoading: false, // 테스트를 위해 비활성화
            ),
          ),
        ),
      );

      // Then
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('빈 리스트 처리', (WidgetTester tester) async {
      // Given
      final items = <String>[];

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String>(
              items: items,
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
              emptyBuilder: (context) => const Text('Empty List'),
            ),
          ),
        ),
      );

      // Then
      expect(find.text('Empty List'), findsOneWidget);
    });
  });
}
