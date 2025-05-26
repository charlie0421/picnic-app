import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 또는 앱 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.apps,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            // 로딩 인디케이터
            const CircularProgressIndicator(),
            const SizedBox(height: 24),

            // 로딩 텍스트
            Text(
              t('loading'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
