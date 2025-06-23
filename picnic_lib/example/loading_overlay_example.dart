import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

/// LoadingOverlay 사용 예시
///
/// 이 파일은 LoadingOverlay의 다양한 사용 방법을 보여줍니다.

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoadingOverlay Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ExampleListScreen(),
    );
  }
}

class ExampleListScreen extends StatelessWidget {
  const ExampleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LoadingOverlay Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildExampleTile(
            context,
            '기본 LoadingOverlay',
            '간단한 로딩 오버레이 사용법',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BasicExampleScreen()),
            ),
          ),
          _buildExampleTile(
            context,
            'Simple LoadingOverlay',
            'Boolean 상태 기반 로딩',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SimpleExampleScreen()),
            ),
          ),
          _buildExampleTile(
            context,
            'Advanced LoadingOverlay',
            'Riverpod과 고급 기능 사용',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdvancedExampleScreen()),
            ),
          ),
          _buildExampleTile(
            context,
            '글로벌 매니저',
            'LoadingOverlayManager 사용법',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManagerExampleScreen()),
            ),
          ),
          _buildExampleTile(
            context,
            '앱 아이콘 애니메이션',
            'LoadingOverlayWithIcon 사용법',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => IconAnimationExampleScreen()),
            ),
          ),
          _buildExampleTile(
            context,
            '성능 최적화 데모',
            '성능 최적화 및 디버그 기능 테스트',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PerformanceOptimizationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

/// 기본 LoadingOverlay 사용 예시
class BasicExampleScreen extends StatelessWidget {
  const BasicExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text('기본 LoadingOverlay'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '기본 LoadingOverlay 예제',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // 로딩 표시
                  context.showLoading();

                  // 3초 후 로딩 숨김
                  Future.delayed(Duration(seconds: 3), () {
                    context.hideLoading();
                  });
                },
                child: Text('3초 로딩 시작'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.isLoadingOverlayVisible) {
                    context.hideLoading();
                  } else {
                    context.showLoading();
                  }
                },
                child: Text('로딩 토글'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple LoadingOverlay 사용 예시
class SimpleExampleScreen extends StatefulWidget {
  const SimpleExampleScreen({super.key});

  @override
  State<SimpleExampleScreen> createState() => _SimpleExampleScreenState();
}

class _SimpleExampleScreenState extends State<SimpleExampleScreen> {
  bool _isLoading = false;
  String _message = '처리 중...';

  void _startProcess() async {
    setState(() {
      _isLoading = true;
      _message = '데이터를 불러오는 중...';
    });

    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _message = '데이터 처리 중...';
    });

    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleLoadingOverlay(
      isLoading: _isLoading,
      message: _message,
      theme: LoadingOverlayTheme.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Simple LoadingOverlay'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Simple LoadingOverlay 예제',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _startProcess,
                child: Text('4초 프로세스 시작'),
              ),
              SizedBox(height: 16),
              Text('상태: ${_isLoading ? "처리 중" : "대기 중"}'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Advanced LoadingOverlay 사용 예시
class AdvancedExampleScreen extends ConsumerWidget {
  const AdvancedExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdvancedLoadingOverlay(
      animationType: LoadingAnimationType.scale,
      theme: LoadingOverlayTheme.blur,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Advanced LoadingOverlay'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Advanced LoadingOverlay 예제',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.showLoadingWithRiverpod(
                        message: 'Fade 애니메이션',
                        animationType: LoadingAnimationType.fade,
                        theme: LoadingOverlayTheme.dark,
                      );
                      Future.delayed(Duration(seconds: 2), () {
                        ref.hideLoadingWithRiverpod();
                      });
                    },
                    child: Text('Fade'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.showLoadingWithRiverpod(
                        message: 'Scale 애니메이션',
                        animationType: LoadingAnimationType.scale,
                        theme: LoadingOverlayTheme.light,
                      );
                      Future.delayed(Duration(seconds: 2), () {
                        ref.hideLoadingWithRiverpod();
                      });
                    },
                    child: Text('Scale'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.showLoadingWithRiverpod(
                        message: 'Slide Up 애니메이션',
                        animationType: LoadingAnimationType.slideUp,
                        theme: LoadingOverlayTheme.transparent,
                      );
                      Future.delayed(Duration(seconds: 2), () {
                        ref.hideLoadingWithRiverpod();
                      });
                    },
                    child: Text('Slide Up'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.showLoadingWithRiverpod(
                        message: 'Blur 테마',
                        animationType: LoadingAnimationType.rotate,
                        theme: LoadingOverlayTheme.blur,
                      );
                      Future.delayed(Duration(seconds: 2), () {
                        ref.hideLoadingWithRiverpod();
                      });
                    },
                    child: Text('Blur + Rotate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LoadingOverlayManager 사용 예시
class ManagerExampleScreen extends StatefulWidget {
  const ManagerExampleScreen({super.key});

  @override
  State<ManagerExampleScreen> createState() => _ManagerExampleScreenState();
}

class _ManagerExampleScreenState extends State<ManagerExampleScreen> {
  final manager = LoadingOverlayManager.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('글로벌 매니저'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LoadingOverlayManager 예제',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                manager.showWithKey(
                  key: 'download',
                  message: '파일 다운로드 중...',
                  theme: LoadingOverlayTheme.dark,
                );
                Future.delayed(Duration(seconds: 3), () {
                  manager.hideWithKey('download');
                });
              },
              child: Text('파일 다운로드 시뮬레이션'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                manager.showWithKey(
                  key: 'upload',
                  message: '파일 업로드 중...',
                  theme: LoadingOverlayTheme.light,
                );
                Future.delayed(Duration(seconds: 3), () {
                  manager.hideWithKey('upload');
                });
              },
              child: Text('파일 업로드 시뮬레이션'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                manager.showWithKey(
                  key: 'sync',
                  message: '데이터 동기화 중...',
                  theme: LoadingOverlayTheme.blur,
                );
                Future.delayed(Duration(seconds: 5), () {
                  manager.hideWithKey('sync');
                });
              },
              child: Text('데이터 동기화'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                manager.hideAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('모든 로딩 중지'),
            ),
            SizedBox(height: 24),
            Text('활성 로딩:'),
            SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: manager.activeKeys.isEmpty
                  ? Center(child: Text('활성 로딩 없음'))
                  : ListView.builder(
                      itemCount: manager.activeKeys.length,
                      itemBuilder: (context, index) {
                        final key = manager.activeKeys[index];
                        final state = manager.getStateWithKey(key);
                        return ListTile(
                          title: Text(key),
                          subtitle: Text(state?.message ?? '메시지 없음'),
                          trailing: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              manager.hideWithKey(key);
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
        tooltip: '상태 새로고침',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

/// 앱 아이콘 애니메이션 LoadingOverlay 사용 예시
class IconAnimationExampleScreen extends StatefulWidget {
  const IconAnimationExampleScreen({super.key});

  @override
  State<IconAnimationExampleScreen> createState() =>
      _IconAnimationExampleScreenState();
}

class _IconAnimationExampleScreenState
    extends State<IconAnimationExampleScreen> {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayWithIcon(
      key: _loadingKey,
      // 모든 애니메이션 활성화 (기본값)
      enableRotation: true,
      enableScale: true,
      enableFade: true,
      // 커스텀 애니메이션 설정
      rotationDuration: Duration(seconds: 3),
      scaleDuration: Duration(milliseconds: 1200),
      fadeDuration: Duration(milliseconds: 800),
      minScale: 0.9,
      maxScale: 1.1,
      loadingMessage: '데이터를 불러오는 중입니다...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('앱 아이콘 애니메이션'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '앱 아이콘 애니메이션 데모',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // 모든 애니메이션 함께
              ElevatedButton(
                onPressed: () {
                  _loadingKey.currentState?.show();
                  Future.delayed(Duration(seconds: 4), () {
                    _loadingKey.currentState?.hide();
                  });
                },
                child: Text('모든 애니메이션 함께 (4초)'),
              ),
              SizedBox(height: 16),

              Text(
                '개별 애니메이션 테스트',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // 회전만
              _buildSimpleAnimationButton('회전 애니메이션만'),
              SizedBox(height: 8),

              // 스케일만
              _buildSimpleAnimationButton('스케일 애니메이션만'),
              SizedBox(height: 8),

              // 페이드만
              _buildSimpleAnimationButton('페이드 애니메이션만'),
              SizedBox(height: 8),

              // 회전 + 스케일
              _buildSimpleAnimationButton('회전 + 스케일'),
              SizedBox(height: 8),

              // 스케일 + 페이드
              _buildSimpleAnimationButton('스케일 + 페이드'),

              SizedBox(height: 24),
              Text(
                '커스텀 설정',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // 빠른 애니메이션
              _buildSimpleAnimationButton('빠른 애니메이션'),
              SizedBox(height: 8),

              // 느린 애니메이션
              _buildSimpleAnimationButton('느린 애니메이션'),
              SizedBox(height: 8),

              // 극적인 스케일
              _buildSimpleAnimationButton('극적인 스케일'),

              SizedBox(height: 24),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleAnimationButton(String title) {
    return ElevatedButton(
      onPressed: () {
        _loadingKey.currentState?.show();
        Future.delayed(Duration(seconds: 3), () {
          _loadingKey.currentState?.hide();
        });
      },
      child: Text(title),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '애니메이션 정보',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text('• 회전: 3초 주기로 시계방향 회전'),
            Text('• 스케일: 0.9 ~ 1.1 크기로 1.2초 주기 변화'),
            Text('• 페이드: 투명도 0.7 ~ 1.0으로 0.8초 주기 변화'),
            Text('• 모든 애니메이션은 동시에 적용 가능'),
            SizedBox(height: 8),
            Text(
              '각 버튼을 눌러서 애니메이션을 확인해보세요!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// 성능 최적화 데모 화면
class PerformanceOptimizationScreen extends StatefulWidget {
  const PerformanceOptimizationScreen({super.key});

  @override
  State<PerformanceOptimizationScreen> createState() =>
      _PerformanceOptimizationScreenState();
}

class _PerformanceOptimizationScreenState
    extends State<PerformanceOptimizationScreen> {
  final GlobalKey<LoadingOverlayWithIconState> _optimizedKey =
      GlobalKey<LoadingOverlayWithIconState>();
  final GlobalKey<LoadingOverlayWithIconState> _nonOptimizedKey =
      GlobalKey<LoadingOverlayWithIconState>();

  bool _showOptimized = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('성능 최적화 데모'),
        actions: [
          Switch(
            value: _showOptimized,
            onChanged: (value) {
              setState(() {
                _showOptimized = value;
              });
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(_showOptimized ? '최적화됨' : '기본'),
            ),
          ),
        ],
      ),
      body: _showOptimized ? _buildOptimizedDemo() : _buildNonOptimizedDemo(),
    );
  }

  Widget _buildOptimizedDemo() {
    return LoadingOverlayWithIcon(
      key: _optimizedKey,
      enablePerformanceOptimization: true,
      showPerformanceDebugInfo: true,
      enableRotation: true,
      enableScale: true,
      enableFade: true,
      rotationDuration: Duration(milliseconds: 1000),
      scaleDuration: Duration(milliseconds: 800),
      fadeDuration: Duration(milliseconds: 600),
      loadingMessage: '성능 최적화 모드로 실행 중...',
      child: _buildDemoContent('최적화된 모드'),
    );
  }

  Widget _buildNonOptimizedDemo() {
    return LoadingOverlayWithIcon(
      key: _nonOptimizedKey,
      enablePerformanceOptimization: false,
      showPerformanceDebugInfo: true,
      enableRotation: true,
      enableScale: true,
      enableFade: true,
      rotationDuration: Duration(milliseconds: 1000),
      scaleDuration: Duration(milliseconds: 800),
      fadeDuration: Duration(milliseconds: 600),
      loadingMessage: '일반 모드로 실행 중...',
      child: _buildDemoContent('일반 모드'),
    );
  }

  Widget _buildDemoContent(String modeTitle) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modeTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  if (_showOptimized) ...[
                    Text('🚀 최적화 기능:'),
                    Text('• 지연 초기화로 메모리 절약'),
                    Text('• RepaintBoundary 최적화'),
                    Text('• 단일 AnimatedBuilder 사용'),
                    Text('• 실시간 FPS 모니터링'),
                    Text('• GPU 가속 활용'),
                  ] else ...[
                    Text('⚠️ 일반 모드:'),
                    Text('• 모든 애니메이션 컨트롤러 생성'),
                    Text('• 개별 RepaintBoundary 사용'),
                    Text('• 다중 AnimatedBuilder 사용'),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // 성능 테스트 버튼들
          Text(
            '성능 테스트',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => _runPerformanceTest(5),
            child: Text('5초 성능 테스트'),
          ),
          SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => _runPerformanceTest(10),
            child: Text('10초 성능 테스트'),
          ),
          SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => _runStressTest(),
            child: Text('스트레스 테스트 (빠른 애니메이션)'),
          ),
          SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => _runBurstTest(),
            child: Text('버스트 테스트 (반복 on/off)'),
          ),
          SizedBox(height: 16),

          // 정보 카드
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '성능 디버그 정보',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• 화면 우상단에 실시간 FPS 표시'),
                  Text('• 프레임 카운트 추적'),
                  Text('• 최적화 모드 상태 표시'),
                  Text('• 개발 모드에서만 활성화'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 애니메이션 컨트롤
          Text(
            '애니메이션 제어',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final key =
                        _showOptimized ? _optimizedKey : _nonOptimizedKey;
                    key.currentState?.show();
                  },
                  child: Text('로딩 시작'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final key =
                        _showOptimized ? _optimizedKey : _nonOptimizedKey;
                    key.currentState?.hide();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('로딩 중지'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _runPerformanceTest(int seconds) {
    final key = _showOptimized ? _optimizedKey : _nonOptimizedKey;
    key.currentState?.show();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$seconds초 성능 테스트 시작 - 우상단 FPS 확인'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(seconds: seconds), () {
      key.currentState?.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('성능 테스트 완료'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _runStressTest() {
    final key = _showOptimized ? _optimizedKey : _nonOptimizedKey;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('스트레스 테스트 시작 - 고속 애니메이션'),
        duration: Duration(seconds: 2),
      ),
    );

    // 빠른 애니메이션으로 스트레스 테스트
    key.currentState?.show();

    Future.delayed(Duration(seconds: 8), () {
      key.currentState?.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스트레스 테스트 완료'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _runBurstTest() async {
    final key = _showOptimized ? _optimizedKey : _nonOptimizedKey;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('버스트 테스트 시작 - 빠른 on/off 반복'),
        duration: Duration(seconds: 2),
      ),
    );

    // 10번 빠른 on/off 반복
    for (int i = 0; i < 10; i++) {
      key.currentState?.show();
      await Future.delayed(Duration(milliseconds: 200));
      key.currentState?.hide();
      await Future.delayed(Duration(milliseconds: 200));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('버스트 테스트 완료'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }
}
