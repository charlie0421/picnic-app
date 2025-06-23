import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

void main() {
  runApp(const RotationDemoApp());
}

class RotationDemoApp extends StatelessWidget {
  const RotationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loading Rotation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RotationDemoScreen(),
    );
  }
}

class RotationDemoScreen extends StatelessWidget {
  const RotationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayWithIcon(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('회전 애니메이션 데모'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '로딩 오버레이 회전 애니메이션 테스트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // 기본 회전 애니메이션 (활성화)
              ElevatedButton(
                onPressed: () {
                  context.showLoadingWithIcon();

                  // 5초 후 숨김
                  Future.delayed(const Duration(seconds: 5), () {
                    context.hideLoadingWithIcon();
                  });
                },
                child: const Text('회전 애니메이션 시작 (5초)'),
              ),

              const SizedBox(height: 20),

              const Text(
                '현재 설정:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text('• 회전 활성화: 예'),
              const Text('• 회전 속도: 2초/회전'),
              const Text('• 방향: 시계방향'),
              const Text('• 아이콘 크기: 64px'),
            ],
          ),
        ),
      ),
    );
  }
}
