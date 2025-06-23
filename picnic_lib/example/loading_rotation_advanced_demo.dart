import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

void main() {
  runApp(const AdvancedRotationDemoApp());
}

class AdvancedRotationDemoApp extends StatelessWidget {
  const AdvancedRotationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Loading Rotation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdvancedRotationDemoScreen(),
    );
  }
}

class AdvancedRotationDemoScreen extends StatefulWidget {
  const AdvancedRotationDemoScreen({super.key});

  @override
  State<AdvancedRotationDemoScreen> createState() =>
      _AdvancedRotationDemoScreenState();
}

class _AdvancedRotationDemoScreenState
    extends State<AdvancedRotationDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고급 회전 애니메이션 데모'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '다양한 회전 옵션 테스트',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // 1. 기본 회전 (시계방향, 2초)
                  _buildDemoCard(
                    '기본 회전',
                    '시계방향, 2초/회전',
                    () => _showLoadingWithOptions(
                      enableRotation: true,
                      rotationDuration: const Duration(seconds: 2),
                      clockwise: true,
                      message: '기본 회전 중...',
                    ),
                  ),

                  // 2. 빠른 회전 (시계방향, 1초)
                  _buildDemoCard(
                    '빠른 회전',
                    '시계방향, 1초/회전',
                    () => _showLoadingWithOptions(
                      enableRotation: true,
                      rotationDuration: const Duration(seconds: 1),
                      clockwise: true,
                      message: '빠른 회전 중...',
                    ),
                  ),

                  // 3. 느린 회전 (시계방향, 4초)
                  _buildDemoCard(
                    '느린 회전',
                    '시계방향, 4초/회전',
                    () => _showLoadingWithOptions(
                      enableRotation: true,
                      rotationDuration: const Duration(seconds: 4),
                      clockwise: true,
                      message: '느린 회전 중...',
                    ),
                  ),

                  // 4. 반시계방향 회전
                  _buildDemoCard(
                    '반시계방향 회전',
                    '반시계방향, 2초/회전',
                    () => _showLoadingWithOptions(
                      enableRotation: true,
                      rotationDuration: const Duration(seconds: 2),
                      clockwise: false,
                      message: '반시계방향 회전 중...',
                    ),
                  ),

                  // 5. 회전 비활성화
                  _buildDemoCard(
                    '회전 비활성화',
                    '정적 아이콘',
                    () => _showLoadingWithOptions(
                      enableRotation: false,
                      rotationDuration: const Duration(seconds: 2),
                      clockwise: true,
                      message: '정적 로딩 중...',
                    ),
                  ),

                  // 6. 큰 아이콘 + 빠른 회전
                  _buildDemoCard(
                    '큰 아이콘',
                    '96px, 빠른 회전',
                    () => _showLoadingWithOptions(
                      enableRotation: true,
                      rotationDuration: const Duration(milliseconds: 800),
                      clockwise: true,
                      iconSize: 96.0,
                      message: '큰 아이콘 회전 중...',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCard(String title, String description, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Icon(Icons.play_arrow, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingWithOptions({
    required bool enableRotation,
    required Duration rotationDuration,
    required bool clockwise,
    required String message,
    double iconSize = 64.0,
  }) {
    // 현재 화면 위에 새로운 화면을 push하여 독립적인 LoadingOverlayWithIcon 위젯을 표시
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoadingOverlayWithIcon(
          enableRotation: enableRotation,
          rotationDuration: rotationDuration,
          clockwise: clockwise,
          iconSize: iconSize,
          loadingMessage: message,
          messageStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(), // 투명한 배경
          ),
        ),
      ),
    );

    // 자동으로 로딩 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = LoadingOverlayWithIcon.of(context);
      overlay?.show();

      // 4초 후 자동 닫기
      Future.delayed(const Duration(seconds: 4), () {
        overlay?.hide();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      });
    });
  }
}
