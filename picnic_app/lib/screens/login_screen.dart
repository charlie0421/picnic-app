import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
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
            SupaEmailAuth(
              redirectTo: kIsWeb ? null : 'fan.picnic/app://home',
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
            SupaSocialsAuth(
              colored: true,
              nativeGoogleAuthConfig: const NativeGoogleAuthConfig(
                webClientId:
                    '853406219989-clb0k1ni6i7t4an7j6h462hin2og0ebu.apps.googleusercontent.com',
                iosClientId:
                    '853406219989-ntnler0e2qe0gfheh3qdjt3k2h4kpvj4.apps.googleusercontent.com',
              ),
              enableNativeAppleAuth: false,
              socialProviders: OAuthProvider.values,
              onSuccess: (session) {
                globalStorage.saveData('ACCESS_TOKEN', session.accessToken);
                globalStorage.saveData(
                    'REFRESH_TOKEN', session.refreshToken ?? '');

                logger.w('onSuccess: $session');
                Navigator.of(context).pushReplacementNamed('/home');
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
