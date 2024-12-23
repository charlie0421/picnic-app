import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({required this.isAuthenticated, this.user});
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState(isAuthenticated: false)) {
    _initialize();
  }

  void _initialize() {
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          state = AuthState(isAuthenticated: true, user: session?.user);
          break;
        case AuthChangeEvent.signedOut:
          state = AuthState(isAuthenticated: false);
          break;
        case AuthChangeEvent.userUpdated:
          state = AuthState(isAuthenticated: true, user: session?.user);
          break;
        default:
          break;
      }
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});
