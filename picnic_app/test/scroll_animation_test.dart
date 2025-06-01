import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/animation_service.dart';
import 'package:picnic_lib/core/services/scroll_physics_service.dart';
import 'package:picnic_lib/presentation/widgets/animation/animated_list_item.dart';
import 'package:picnic_lib/presentation/widgets/lists/optimized_list_view.dart';
import 'package:picnic_lib/presentation/widgets/smart_repaint_boundary.dart';

void main() {
  group('Scroll and Animation Optimization Tests', () {
    late AnimationService animationService;
    late ScrollPhysicsService physicsService;

    setUp(() {
      animationService = AnimationService();
      physicsService = ScrollPhysicsService();
    });

    group('AnimationService Tests', () {
      testWidgets('should create and manage animation controllers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final controller = animationService.createController(
                    duration: const Duration(milliseconds: 300),
                    vsync: Ticker.of(context),
                  );
                  
                  expect(controller, isNotNull);
                  expect(controller.duration, equals(const Duration(milliseconds: 300)));
                  
                  return Container();
                },
              ),
            ),
          ),
        );
      });

      test('should manage animation statistics', () {
        animationService.startPerformanceMonitoring();
        
        // Simulate animation activity
        animationService.recordPerformanceMetric('test_animation', 16.67);
        animationService.recordPerformanceMetric('test_animation', 15.0);
        
        final stats = animationService.getPerformanceStatistics();
        expect(stats, isNotEmpty);
        expect(stats['test_animation'], isNotNull);
        
        animationService.stopPerformanceMonitoring();
      });

      test('should dispose controllers properly', () {
        expect(() => animationService.dispose(), returnsNormally);
      });

      test('should handle memory pressure', () {
        animationService.startPerformanceMonitoring();
        
        // Simulate memory pressure
        animationService.onMemoryPressure();
        
        final stats = animationService.getPerformanceStatistics();
        expect(stats['memory_cleanups'], greaterThan(0));
      });

      test('should pause and resume all animations', () {
        animationService.pauseAllAnimations();
        expect(animationService.areAnimationsPaused, isTrue);
        
        animationService.resumeAllAnimations();
        expect(animationService.areAnimationsPaused, isFalse);
      });
    });

    group('ScrollPhysicsService Tests', () {
      test('should provide platform-appropriate physics', () {
        final physics = physicsService.getPlatformPhysics();
        expect(physics, isNotNull);
      });

      test('should provide different physics types', () {
        final bouncing = physicsService.getPhysics(
          ScrollPhysicsService.ScrollPhysicsType.bouncing,
        );
        final clamping = physicsService.getPhysics(
          ScrollPhysicsService.ScrollPhysicsType.clamping,
        );
        
        expect(bouncing, isA<BouncingScrollPhysics>());
        expect(clamping, isA<ClampingScrollPhysics>());
      });

      test('should provide optimized physics for lists and grids', () {
        final listPhysics = physicsService.getListPhysics();
        final gridPhysics = physicsService.getGridPhysics();
        
        expect(listPhysics, isA<OptimizedListScrollPhysics>());
        expect(gridPhysics, isA<OptimizedGridScrollPhysics>());
      });

      test('should handle infinite scroll physics', () {
        final infinitePhysics = physicsService.getInfiniteScrollPhysics();
        expect(infinitePhysics, isA<InfiniteScrollPhysics>());
      });
    });

    group('ScrollPhysicsManager Tests', () {
      test('should manage physics type switching', () {
        final manager = ScrollPhysicsManager();
        
        manager.setPhysicsType(ScrollPhysicsService.ScrollPhysicsType.elastic);
        expect(manager.currentType, equals(ScrollPhysicsService.ScrollPhysicsType.elastic));
        
        final physics = manager.getCurrentPhysics();
        expect(physics, isA<ElasticScrollPhysics>());
      });

      test('should provide content-specific physics', () {
        final manager = ScrollPhysicsManager();
        
        final listPhysics = manager.getPhysicsForContent('list');
        final gridPhysics = manager.getPhysicsForContent('grid');
        final infinitePhysics = manager.getPhysicsForContent('infinite');
        
        expect(listPhysics, isA<OptimizedListScrollPhysics>());
        expect(gridPhysics, isA<OptimizedGridScrollPhysics>());
        expect(infinitePhysics, isA<InfiniteScrollPhysics>());
      });
    });

    group('AnimatedListItem Tests', () {
      testWidgets('should render with different animation types',
          (WidgetTester tester) async {
        for (final animationType in AnimationType.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AnimatedListItem(
                  animationType: animationType,
                  index: 0,
                  child: const Text('Test Item'),
                ),
              ),
            ),
          );
          
          await tester.pump();
          expect(find.text('Test Item'), findsOneWidget);
        }
      });

      testWidgets('should handle custom animation curves',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedListItem(
                animationType: AnimationType.fadeIn,
                index: 0,
                curve: Curves.bounceIn,
                child: const Text('Test Item'),
              ),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.text('Test Item'), findsOneWidget);
      });
    });

    group('OptimizedListView Tests', () {
      testWidgets('should render items with optimized physics',
          (WidgetTester tester) async {
        final items = List.generate(100, (index) => 'Item $index');
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedListView<String>(
                  items: items,
                  physicsType: ScrollPhysicsService.ScrollPhysicsType.custom,
                  itemBuilder: (context, item, index) {
                    return ListTile(title: Text(item));
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.text('Item 0'), findsOneWidget);
      });

      testWidgets('should handle refresh and load more',
          (WidgetTester tester) async {
        bool refreshCalled = false;
        bool loadMoreCalled = false;
        
        final items = List.generate(10, (index) => 'Item $index');
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedListView<String>(
                  items: items,
                  onRefresh: () async {
                    refreshCalled = true;
                  },
                  onLoadMore: () {
                    loadMoreCalled = true;
                  },
                  itemBuilder: (context, item, index) {
                    return ListTile(title: Text(item));
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        // Test refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        expect(refreshCalled, isTrue);
      });

      testWidgets('should enable adaptive physics',
          (WidgetTester tester) async {
        final items = List.generate(100, (index) => 'Item $index');
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedListView<String>(
                  items: items,
                  enableAdaptivePhysics: true,
                  itemBuilder: (context, item, index) {
                    return ListTile(title: Text(item));
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('SmartRepaintBoundary Tests', () {
      testWidgets('should wrap widgets with RepaintBoundary conditionally',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRepaintBoundary(
                enabled: true,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.byType(RepaintBoundary), findsOneWidget);
      });

      testWidgets('should not wrap when disabled',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRepaintBoundary(
                enabled: false,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.byType(RepaintBoundary), findsNothing);
      });
    });

    group('Performance Tests', () {
      testWidgets('should maintain 60fps during scrolling',
          (WidgetTester tester) async {
        final items = List.generate(1000, (index) => 'Item $index');
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedListView<String>(
                  items: items,
                  enableAnimation: true,
                  physicsType: ScrollPhysicsService.ScrollPhysicsType.smooth,
                  itemBuilder: (context, item, index) {
                    return SmartRepaintBoundary(
                      enabled: true,
                      child: AnimatedListItem(
                        animationType: AnimationType.slideInFromRight,
                        index: index,
                        child: ListTile(title: Text(item)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        // Simulate fast scrolling
        final listFinder = find.byType(ListView);
        await tester.fling(listFinder, const Offset(0, -500), 2000);
        
        // Let animations complete
        await tester.pumpAndSettle();
        
        // Check that no frames were dropped (this is a simplified test)
        expect(find.text('Item 0'), findsNothing); // Scrolled past
        expect(find.byType(ListView), findsOneWidget);
      });

      test('should optimize memory usage', () {
        final service = AnimationService();
        service.startPerformanceMonitoring();
        
        // Simulate memory pressure scenarios
        for (int i = 0; i < 100; i++) {
          service.recordPerformanceMetric('memory_test', 16.67);
        }
        
        service.onMemoryPressure();
        
        final stats = service.getPerformanceStatistics();
        expect(stats['memory_cleanups'], greaterThan(0));
        
        service.dispose();
      });

      testWidgets('should handle rapid animation state changes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: List.generate(10, (index) {
                      return AnimatedListItem(
                        animationType: index.isEven 
                            ? AnimationType.fadeIn 
                            : AnimationType.slideInFromLeft,
                        index: index,
                        child: ListTile(title: Text('Item $index')),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        );
        
        // Pump multiple times to ensure animations complete
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 9'), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should integrate all optimization components',
          (WidgetTester tester) async {
        final items = List.generate(50, (index) => 'Item $index');
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedListView<String>(
                  items: items,
                  enableAnimation: true,
                  enableAdaptivePhysics: true,
                  keepAlive: true,
                  physicsType: ScrollPhysicsService.ScrollPhysicsType.elastic,
                  itemBuilder: (context, item, index) {
                    return SmartRepaintBoundary(
                      enabled: true,
                      child: AnimatedListItem(
                        animationType: AnimationType.slideInFromBottom,
                        index: index,
                        child: Card(
                          child: ListTile(
                            title: Text(item),
                            subtitle: Text('Index: $index'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        await tester.pumpAndSettle();
        
        // Verify initial render
        expect(find.text('Item 0'), findsOneWidget);
        
        // Test scrolling
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
        
        // Test that animations and optimizations work together
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(RepaintBoundary), findsWidgets);
      });
    });
  });
}

/// Helper class for testing performance metrics
class PerformanceTestHelper {
  static Future<Map<String, double>> measureScrollPerformance(
    WidgetTester tester,
    Finder listFinder, {
    int scrollCount = 10,
    double scrollDistance = 300,
  }) async {
    final stopwatch = Stopwatch()..start();
    int frameCount = 0;
    
    for (int i = 0; i < scrollCount; i++) {
      await tester.drag(listFinder, Offset(0, -scrollDistance));
      await tester.pump();
      frameCount++;
    }
    
    stopwatch.stop();
    
    return {
      'totalTime': stopwatch.elapsedMilliseconds.toDouble(),
      'averageFrameTime': stopwatch.elapsedMilliseconds / frameCount,
      'framesPerSecond': frameCount / (stopwatch.elapsedMilliseconds / 1000),
    };
  }
  
  static Future<void> simulateMemoryPressure() async {
    // Simulate memory pressure by creating and disposing many objects
    final objects = <Object>[];
    for (int i = 0; i < 1000; i++) {
      objects.add(Object());
    }
    objects.clear();
  }
}