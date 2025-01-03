import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Icons.update,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  '업데이트 필요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '앱의 최신 버전으로 업데이트 해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: const Text('종료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
