import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/core/utils/logger.dart';

import 'url_strategy.dart' if (dart.html) 'url_strategy_web.dart' as strategy;

class OAuthCallbackPage extends ConsumerStatefulWidget {
  final Uri callbackUri;
  static const routeName = '/auth/callback';

  const OAuthCallbackPage({super.key, required this.callbackUri});

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    try {
      final code = widget.callbackUri.queryParameters['code'];
      logger.d('Processing OAuth callback with code: $code');

      if (code == null) {
        throw Exception('로그인에 실패했습니다: 인증 코드가 없습니다');
      }

// 인증 코드로 세션 교환
      logger.d('Successfully exchanged code for session');

      if (mounted) {
// web 플랫폼인 경우에만 URL 파라미터 제거
        if (kIsWeb) {
          strategy.clearUrlParameters();
        }
        _navigateToHome();
      }
    } catch (e, s) {
      logger.e('Error handling OAuth callback', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _retryAuthentication() {
    setState(() {
      _error = null;
    });
    _handleOAuthCallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _error != null ? _buildErrorState() : _buildLoadingState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          '로그인 처리중...',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          '로그인 오류',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? '알 수 없는 오류가 발생했습니다',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _retryAuthentication,
          child: const Text('다시 시도'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _navigateToHome,
          child: const Text('홈으로 돌아가기'),
        ),
      ],
    );
  }
}
