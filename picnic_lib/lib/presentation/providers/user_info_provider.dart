import 'dart:async';
import 'dart:convert';

import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider_helper.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, Session, SupabaseClient;

part '../../generated/providers/user_info_provider.g.dart';

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  StreamSubscription? _configSubscription;

  @override
  Future<UserProfilesModel?> build() async {
    if (!isSupabaseLoggedSafely) {
      logger.i('User is not logged in');
      return null;
    }

    final profile = await getUserProfiles();

    ref.onDispose(() {
      logger.i('Disposing UserInfo provider');
      _configSubscription?.cancel();
    });

    return profile;
  }

  Future<UserProfilesModel?> getUserProfiles() async {
    if (!isSupabaseLoggedSafely) {
      logger.i('User is not logged in');
      return null;
    }

    try {
      // Legacy profile balances remain for compatibility; new wallet UI must
      // read authoritative balances from walletSummaryProvider.
      final response = await supabase
          .from('user_profiles')
          .select(
            'id,avatar_url,star_candy,nickname,email,star_candy_bonus,is_admin,is_super_admin,birth_date,gender,birth_time,deleted_at,user_agreement(id,terms,privacy)',
          )
          .eq('id', supabase.auth.currentUser!.id)
          .maybeSingle();

      logger.i('User profiles response: $response');
      if (response != null) {
        final userProfile = UserProfilesModel.fromJson(response);
        state = AsyncValue.data(userProfile);

        return userProfile;
      } else {
        logger.w('User profile not found');
        return null;
      }
    } catch (e, s) {
      logger.e('Error getting user profiles', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);

      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<void> updateProfile({
    String? gender,
    DateTime? birthDate,
    String? birthTime,
  }) async {
    logger.i('Updating profile - gender: $gender, birthDate: $birthDate');
    try {
      if (!isSupabaseLoggedSafely) {
        logger.w('Cannot update profile: user not logged in');
        return;
      }

      final updates = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: gender,
        birthDate: birthDate,
        birthTime: birthTime,
        updatedAt: DateTime.now(),
      );

      await supabase.from('user_profiles').upsert({
        'id': supabase.auth.currentUser!.id,
        ...updates,
      });

      // Refresh the profile
      await getUserProfiles();

      logger.i('Profile updated successfully');
    } catch (e, s) {
      logger.e('Error updating profile', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> logout() async {
    final authService = AuthService();
    authService.signOut();

    ref.read(navigationInfoProvider.notifier).setBottomNavigationIndex(0);

    state = const AsyncValue.data(null);
    logger.i('User logged out');
  }

  Future<bool> updateNickname(String nickname) async {
    logger.i('Updating nickname to: $nickname');
    try {
      final response = await supabase.functions.invoke(
        'update-nickname',
        body: {'nickname': nickname},
      );

      final updatedProfile = UserInfoProviderHelper.parseNicknameResponse(
        status: response.status,
        data: response.data,
      );
      if (updatedProfile == null) {
        final error = jsonDecode(response.data)['error'];
        logger.e('Error updating nickname: $error');
        return false;
      }

      state = AsyncValue.data(updatedProfile);
      logger.i('Nickname updated successfully: ${updatedProfile.nickname}');
      return true;
    } catch (e, s) {
      logger.e(
        'Error calling update-nickname function',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<void> updateAvatar(String url) async {
    // 요청을 보낸 계정과 클라이언트. 응답을 기다리는 동안 바뀔 수 있다.
    final client = supabase;
    final owner = _AvatarOwner(client, client.auth.currentUser!.id);
    // 컨테이너가 폐기되거나 다시 빌드되면 구독을 끝내고 결과를 쓰지 않는다.
    ref.onDispose(owner.close);
    try {
      logger.i('Updating avatar URL');
      await client
          .from('user_profiles')
          .update({'avatar_url': url})
          .eq('id', owner.userId);

      // 요청을 보낸 계정이 그 사이 한 번이라도 바뀌었으면(A → B → A 포함) 이
      // 결과를 쓰지 않는다. 지금 상태는 다시 로그인한 계정의 새 프로필일 수
      // 있고, 이 URL 로 덮으면 그 프로필이 잘못된 사진을 보여 준다.
      //
      // 확인 결과를 받는 await 도 microtask 한 번을 거친다. 그 사이 세션이
      // 바뀔 수 있으므로 여기서 같은 턴에 다시 본다. 세션이 바뀌었으면 다시
      // 확인해 아직 전달되지 않은 전환을 받아 낸다.
      while (true) {
        if (!await _confirmAvatarOwner(owner) ||
            !ref.mounted ||
            !owner.isCurrent) {
          logger.i('Avatar update finished for a previous account');
          return;
        }
        if (identical(owner.client.auth.currentSession, owner.session)) break;
      }
      // 마지막 확인과 대입 사이에 await 가 없다.
      final current = state.value;
      if (current == null || current.id != owner.userId) {
        logger.i('Avatar update finished for a previous account');
        return;
      }
      state = AsyncValue.data(current.copyWith(avatarUrl: url));
      logger.i('Avatar URL updated successfully');
    } finally {
      owner.close();
    }
  }

  /// [owner] 의 계정이 같은 클라이언트에서, 전환 없이 아직 로그인해 있는지.
  ///
  /// 세션 인스턴스만 바뀌었으면 같은 계정의 토큰 갱신일 수도, 이벤트가 아직
  /// 전달되지 않은 계정 전환(A → B → A 포함)일 수도 있다. gotrue 는 세션을
  /// 바꾸는 턴에 이벤트를 microtask 로 예약하므로, 타이머 한 번 뒤 다시
  /// 확인한다. 그 사이 세션이 그대로면 같은 계정의 새 세션으로 받아들인다.
  Future<bool> _confirmAvatarOwner(_AvatarOwner owner) async {
    while (true) {
      if (!ref.mounted || !owner.isCurrent) return false;
      final session = owner.client.auth.currentSession;
      if (identical(session, owner.session)) return true;
      await Future<void>.delayed(Duration.zero);
      if (!ref.mounted || !owner.isCurrent) return false;
      if (identical(owner.client.auth.currentSession, session)) {
        owner.session = session;
        return true;
      }
    }
  }

  /// 사용자 언어 설정을 업데이트합니다.
  Future<void> updateLanguage(String languageCode) async {
    if (!isSupabaseLoggedSafely) {
      logger.w('Cannot update language: user not logged in');
      return;
    }

    try {
      final normalizedLanguage =
          UserInfoProviderHelper.normalizeLanguageCode(languageCode);

      logger.i(
        'Updating user language to: $normalizedLanguage (original: $languageCode)',
      );

      await supabase
          .from('user_profiles')
          .update({
            'language': normalizedLanguage,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', supabase.auth.currentUser!.id);

      logger.i('User language updated successfully');
    } catch (e, s) {
      logger.e('Error updating user language', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      // 언어 업데이트 실패는 치명적이지 않으므로 rethrow하지 않음
    }
  }
}

/// 아바타 변경 요청 하나의 소유자. 요청을 보낸 계정과 클라이언트를 갖고,
/// 응답을 기다리는 동안 그 클라이언트에서 일어난 계정 전환을 센다.
final class _AvatarOwner {
  _AvatarOwner(this.client, this.userId)
    : session = client.auth.currentSession {
    String? current = userId;
    _events = client.auth.onAuthStateChange.listen(
      (state) {
        if (_closed) return;
        final next = state.session?.user.id;
        if (next == current) return;
        current = next;
        _transitions++;
      },
      // 인증 오류에는 세션 정보가 담길 수 있다. 기록하지 않는다.
      onError: (Object _, StackTrace _) {},
    );
  }

  final SupabaseClient client;
  final String userId;

  /// 비교에만 쓴다. 세션 내용은 읽거나 기록하지 않는다.
  Session? session;

  StreamSubscription<AuthState>? _events;
  int _transitions = 0;
  bool _closed = false;

  /// 닫히지 않았고, 전환이 관측되지 않았고, [client] 가 아직 현재
  /// 클라이언트이며 [userId] 로 로그인돼 있는지.
  bool get isCurrent =>
      !_closed && _transitions == 0 && _isSignedInAs(client, userId);

  /// 구독을 끝낸다. 여러 번 불러도 된다.
  void close() {
    if (_closed) return;
    _closed = true;
    unawaited(_events?.cancel());
    _events = null;
  }
}

/// [client] 가 아직 현재 클라이언트이고 [userId] 로 로그인돼 있는지.
bool _isSignedInAs(Object client, String userId) {
  try {
    return identical(supabase, client) &&
        supabase.auth.currentUser?.id == userId;
  } on StateError {
    // 클라이언트가 더 이상 없다.
    return false;
  }
}

@riverpod
Future<bool> setAgreement(Ref ref) async {
  logger.i('Setting user agreement');
  if (!isSupabaseLoggedSafely) {
    logger.w('Cannot set agreement: user not logged in');
    return false;
  }
  try {
    await supabase.auth.refreshSession();
    await supabase.from('user_agreement').upsert({
      'id': supabase.auth.currentUser!.id,
      'terms': 'now',
      'privacy': 'now',
    }).select();

    logger.i('User agreement set successfully');
    return true;
  } catch (e, s) {
    logger.e('Error setting user agreement', error: e, stackTrace: s);
    return false;
  }
}

@riverpod
Future<bool> agreement(Ref ref) async {
  logger.i('Creating user agreement');
  if (!isSupabaseLoggedSafely) {
    logger.w('Cannot create agreement: user not logged in');
    return false;
  }
  try {
    await supabase.auth.refreshSession();
    await supabase.from('user_agreement').insert({
      'id': supabase.auth.currentUser!.id,
      'terms': DateTime.now().toUtc(),
      'privacy': DateTime.now().toUtc(),
    }).select();

    logger.i('User agreement created successfully');
    return true;
  } catch (e, s) {
    logger.e('Error creating user agreement', error: e, stackTrace: s);
    return false;
  }
}

@riverpod
Future<List<Map<String, dynamic>?>?> expireBonus(Ref ref) async {
  logger.i('Calculating expire bonus');
  try {
    final response = await supabase.functions.invoke(
      'expiring-bonus',
      body: {},
    );
    logger.i('[expireBonus] HTTP status: ${response.status}');
    // response.data는 string일 수 있음
    final raw = response.data;
    logger.i('[expireBonus] raw length: ${raw is String ? raw.length : -1}');
    if (response.status != 200) {
      logger.e('[expireBonus] non-200: ${response.status} body: $raw');
      throw Exception('expiring-bonus failed: ${response.status}');
    }

    final parsed = raw is String ? jsonDecode(raw) : raw;
    final result = UserInfoProviderHelper.parseExpireBonusResponse(parsed);

    if (result != null) {
      logger.i('[expireBonus] parsed length: ${result.length}');
      for (final item in result) {
        logger.i(
          '[expireBonus] item month=${item['prediction_month']} amount=${item['expiring_amount']}',
        );
      }
      return result;
    }

    throw Exception('Unexpected response format: ${parsed.runtimeType}');
  } catch (e, s) {
    logger.e('Error calculating expire bonus', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return null;
  }
}
