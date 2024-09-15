import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/supabase_options.dart';

class OAuthCallbackPage extends StatefulWidget {
  final Uri callbackUri;

  const OAuthCallbackPage({Key? key, required this.callbackUri})
      : super(key: key);

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

        if (response.session != null) {
          // 성공적인 인증 후 처리
          Navigator.of(context).pop();
        } else {
          throw Exception('Failed to exchange code for session');
        }
      } else {
        throw Exception('Invalid OAuth callback: missing code');
      }
    } catch (e, s) {
      logger.e('Error handling OAuth callback: $e', stackTrace: s);
      // 에러 처리...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
