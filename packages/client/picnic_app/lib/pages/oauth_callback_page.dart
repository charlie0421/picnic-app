import 'package:flutter/material.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/supabase_options.dart';

class OAuthCallbackPage extends StatefulWidget {
  final Uri callbackUri;

  const OAuthCallbackPage({super.key, required this.callbackUri});

  @override
  _OAuthCallbackPageState createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  @override
  void initState() {
    logger.d('OAuthCallbackPage:initState ${widget.callbackUri}');
    super.initState();
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    try {
      final code = widget.callbackUri.queryParameters['code'];
      logger.d('OAuthCallbackPage:code $code');
      if (code != null) {
        final response = await supabase.auth.exchangeCodeForSession(code);

        logger.d('OAuthCallbackPage:response $response');

        // 성공적인 인증 후 처리
        Navigator.of(context).pop();
      } else {
        throw Exception('Invalid OAuth callback: missing code');
      }
    } catch (e, s) {
      logger.e('Error handling OAuth callback: $e', stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
