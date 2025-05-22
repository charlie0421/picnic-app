import 'package:flutter/material.dart';

class BanScreen extends StatelessWidget {
  const BanScreen({
    super.key, 
    this.reason = '이 기기는 서비스 이용이 제한되었습니다.',
    this.isVirtualDevice = false,
  });

  final String reason;
  final bool isVirtualDevice;

  @override
  Widget build(BuildContext context) {
    final banMessage = isVirtualDevice 
        ? '가상 머신에서는 앱을 실행할 수 없습니다.'
        : reason;

    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  '앱 사용 제한',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  banMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '자세한 내용은 고객센터로 문의해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
