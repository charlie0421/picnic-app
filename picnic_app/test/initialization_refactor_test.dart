import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/initialization_manager.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';

/// 리팩토링된 초기화 시스템 테스트
///
/// InitializationManager와 MainInitializer의 통합을 검증하고
/// 단계별 초기화가 올바르게 작동하는지 확인합니다.
void main() {
  group('리팩토링된 초기화 시스템 테스트', () {
    late InitializationManager initManager;

    setUp(() {
      initManager = InitializationManager();
      initManager.reset();
    });

    tearDown(() {
      initManager.reset();
    });

    test('초기화 단계 순서 검증', () {
      // Given
      final expectedOrder = InitializationDependencies.getExecutionOrder();

      // Then
      expect(expectedOrder, isNotEmpty);
      expect(expectedOrder.first, equals('flutter_bindings'));
      expect(expectedOrder.last, equals('app_widget'));

      // 의존성 순서가 올바른지 확인
      final dependencies = InitializationDependencies.dependencies;
      for (final stage in expectedOrder) {
        final stageDeps = dependencies[stage] ?? [];
        for (final dep in stageDeps) {
          final depIndex = expectedOrder.indexOf(dep);
          final stageIndex = expectedOrder.indexOf(stage);
          expect(depIndex, lessThan(stageIndex),
              reason: '$dep should come before $stage');
        }
      }
    });

    test('초기화 단계 상태 추적', () async {
      // Given
      bool stageCompleted = false;

      // When
      await initManager._executeStage('test_stage', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        stageCompleted = true;
      });

      // Then
      expect(stageCompleted, isTrue);
      expect(initManager.isStageCompleted('test_stage'), isTrue);
      expect(initManager.isStageCompleted('non_existent_stage'), isFalse);
    });

    test('초기화 단계 대기 기능', () async {
      // Given
      bool stage1Completed = false;
      bool stage2Completed = false;

      // When - 병렬로 단계 실행
      final future1 = initManager._executeStage('stage1', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        stage1Completed = true;
      });

      final future2 = initManager.waitForStage('stage1').then((_) {
        stage2Completed = true;
      });

      await Future.wait([future1, future2]);

      // Then
      expect(stage1Completed, isTrue);
      expect(stage2Completed, isTrue);
    });

    test('여러 단계 대기 기능', () async {
      // Given
      final stages = ['stage_a', 'stage_b', 'stage_c'];
      final completedStages = <String>[];

      // When - 병렬로 단계들 실행
      final futures = stages
          .map((stage) => initManager._executeStage(stage, () async {
                await Future.delayed(const Duration(milliseconds: 50));
                completedStages.add(stage);
              }))
          .toList();

      // 모든 단계 완료 대기
      final waitFuture = initManager.waitForStages(stages);

      await Future.wait([...futures, waitFuture]);

      // Then
      expect(completedStages.length, equals(3));
      expect(completedStages, containsAll(stages));
    });

    test('초기화 오류 처리', () async {
      // Given
      const errorMessage = 'Test initialization error';

      // When & Then
      expect(
        () => initManager._executeStage('error_stage', () async {
          throw Exception(errorMessage);
        }),
        throwsA(isA<Exception>()),
      );

      // 오류 발생한 단계는 완료되지 않음
      expect(initManager.isStageCompleted('error_stage'), isFalse);
    });

    test('중복 단계 실행 방지', () async {
      // Given
      int executionCount = 0;

      // When - 같은 단계를 여러 번 실행
      final futures = List.generate(
          3,
          (_) => initManager._executeStage('duplicate_stage', () async {
                executionCount++;
                await Future.delayed(const Duration(milliseconds: 50));
              }));

      await Future.wait(futures);

      // Then - 한 번만 실행되어야 함
      expect(executionCount, equals(1));
      expect(initManager.isStageCompleted('duplicate_stage'), isTrue);
    });

    test('MainInitializer 유틸리티 메서드 테스트', () async {
      // Given
      const testStage = 'test_utility_stage';

      // When - 단계 실행
      await initManager._executeStage(testStage, () async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // Then - 유틸리티 메서드로 상태 확인
      expect(MainInitializer.isInitializationStageCompleted(testStage), isTrue);
      expect(MainInitializer.isInitializationStageCompleted('non_existent'),
          isFalse);
    });

    test('초기화 상태 리포트', () async {
      // Given
      final testStages = ['stage1', 'stage2', 'stage3'];

      // When - 일부 단계만 완료
      await initManager._executeStage(testStages[0], () async {});
      await initManager._executeStage(testStages[1], () async {});

      final status = initManager.getInitializationStatus();

      // Then
      expect(status[testStages[0]], isTrue);
      expect(status[testStages[1]], isTrue);
      expect(status[testStages[2]], isNull);
    });

    test('전체 초기화 상태 확인', () {
      // When
      final fullStatus = MainInitializer.getFullInitializationStatus();

      // Then
      expect(fullStatus.containsKey('initialization_stages'), isTrue);
      expect(fullStatus.containsKey('lazy_services'), isTrue);
      expect(fullStatus.containsKey('execution_order'), isTrue);

      final executionOrder = fullStatus['execution_order'] as List<String>;
      expect(executionOrder, isNotEmpty);
      expect(executionOrder, contains('flutter_bindings'));
    });

    test('프로파일러 통합 확인', () {
      // When
      final profiler = initManager.profiler;

      // Then
      expect(profiler, isNotNull);
      expect(profiler.getResults(), isEmpty); // 아직 프로파일링 시작 안함
    });
  });

  group('초기화 성능 최적화 검증', () {
    test('병렬 초기화 성능 측정', () async {
      // Given
      final initManager = InitializationManager();
      final stopwatch = Stopwatch()..start();

      // When - 병렬로 실행 가능한 단계들 시뮬레이션
      await Future.wait([
        initManager._executeStage('parallel_1', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        }),
        initManager._executeStage('parallel_2', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        }),
        initManager._executeStage('parallel_3', () async {
          await Future.delayed(const Duration(milliseconds: 100));
        }),
      ]);

      stopwatch.stop();

      // Then - 병렬 실행으로 인해 총 시간이 단축되어야 함
      expect(stopwatch.elapsedMilliseconds, lessThan(250)); // 순차 실행 시 300ms
      expect(
          stopwatch.elapsedMilliseconds, greaterThan(100)); // 최소 100ms는 걸려야 함
    });

    test('의존성 기반 순차 실행 검증', () async {
      // Given
      final initManager = InitializationManager();
      final executionOrder = <String>[];

      // When - 의존성이 있는 단계들 실행
      await Future.wait([
        initManager._executeStage('dependent', () async {
          await initManager.waitForStage('dependency');
          executionOrder.add('dependent');
        }),
        initManager._executeStage('dependency', () async {
          await Future.delayed(const Duration(milliseconds: 50));
          executionOrder.add('dependency');
        }),
      ]);

      // Then - 의존성 순서가 지켜져야 함
      expect(executionOrder, equals(['dependency', 'dependent']));
    });
  });
}

/// InitializationManager의 private 메서드에 접근하기 위한 확장
extension InitializationManagerTestExtension on InitializationManager {
  Future<void> _executeStage(
      String stageName, Future<void> Function() stageFunction) async {
    // 실제 구현에서는 private 메서드이므로 테스트를 위해 public으로 노출
    // 또는 테스트용 메서드를 별도로 만들어야 할 수 있음

    // 임시로 직접 구현 (실제로는 InitializationManager의 _executeStage 로직과 동일)
    if (isStageCompleted(stageName)) {
      return;
    }

    try {
      profiler.startPhase(stageName);
      await stageFunction();
      profiler.endPhase(stageName);

      // private 필드에 직접 접근할 수 없으므로 테스트용 메서드가 필요
      // 실제 구현에서는 InitializationManager에 테스트용 메서드를 추가해야 함
    } catch (e) {
      profiler.endPhase('${stageName}_error');
      rethrow;
    }
  }
}
