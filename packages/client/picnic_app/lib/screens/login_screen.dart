import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

const optionText = Text(
  'Or',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  textAlign: TextAlign.center,
);

const spacer = SizedBox(
  height: 12,
);

class LoginScreen extends ConsumerWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            /*
            SupaEmailAuth(
              redirectTo: kIsWeb ? null : 'pic.picnic/app://home',
              onSignInComplete: (response) {
                Navigator.of(context).pushReplacementNamed('/home');
              },
              onSignUpComplete: (response) {
                Navigator.of(context).pushReplacementNamed('/home');
              },
              metadataFields: [
                MetaDataField(
                  prefixIcon: const Icon(Icons.person),
                  label: 'Username',
                  key: 'username',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter something';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const Divider(),
            optionText,
            spacer,
             */
            SupaSocialsAuth(
              colored: true,
              nativeGoogleAuthConfig: const NativeGoogleAuthConfig(
                webClientId:
                    '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com',
                iosClientId:
                    '853406219989-ntnler0e2qe0gfheh3qdjt3k2h4kpvj4.apps.googleusercontent.com',
              ),
              enableNativeAppleAuth: false,
              socialProviders: const [
                OAuthProvider.google,
                OAuthProvider.apple,
                OAuthProvider.kakao
              ],
              redirectUrl: 'pic.picnic.app://login-callback',
              onSuccess: (session) {
                ref.read(loginedProvider.notifier).setLogined(true);
                ref
                    .read(navigationInfoProvider.notifier)
                    .setPortalString('vote');
              },
              onError: (error) {
                logger.e('onError: $error');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreenArguments {
  final String? email;
  final String? password;

  LoginScreenArguments({this.email, this.password});
}
