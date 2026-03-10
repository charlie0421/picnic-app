import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/token_refresh_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthService를 모킹하기 위한 간단한 Mock 클래스
class MockAuthService extends AuthService {
  final StreamController<Session?> _testSessionController =
      StreamController<Session?>.broadcast();

  bool refreshSessionCalled = false;

  MockAuthService() : super();

  @override
  Stream<Session?> get sessionStream => _testSessionController.stream;

  @override
  Future<bool> refreshSession() async {
    refreshSessionCalled = true;
    return true;
  }

  void emitSession(Session? session) {
    _testSessionController.add(session);
  }

  Future<void> closeController() async {
    await _testSessionController.close();
  }
}

void main() {
  group('TokenRefreshManager', () {
    late TokenRefreshManager manager;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      manager = TokenRefreshManager(mockAuthService);
    });

    tearDown(() {
      manager.dispose();
      mockAuthService.closeController();
    });

    test('생성자가 AuthService를 받아 인스턴스를 생성한다', () {
      expect(manager, isA<TokenRefreshManager>());
    });

    test('startPeriodicRefresh가 세션 스트림을 구독한다', () async {
      // startPeriodicRefresh를 호출하면 세션 스트림에 리스너가 등록됨
      manager.startPeriodicRefresh();

      // 세션이 null인 경우를 emit하여 리스너가 등록되었는지 확인
      mockAuthService.emitSession(null);

      // 에러 없이 완료되어야 함
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('stopPeriodicRefresh가 타이머와 구독을 취소한다', () {
      manager.startPeriodicRefresh();
      // stopPeriodicRefresh를 호출해도 에러가 발생하지 않아야 함
      expect(() => manager.stopPeriodicRefresh(), returnsNormally);
    });

    test('stopPeriodicRefresh를 여러 번 호출해도 안전하다', () {
      expect(() {
        manager.stopPeriodicRefresh();
        manager.stopPeriodicRefresh();
      }, returnsNormally);
    });

    test('dispose가 stopPeriodicRefresh를 호출한다', () {
      manager.startPeriodicRefresh();
      // dispose를 호출해도 에러가 발생하지 않아야 함
      expect(() => manager.dispose(), returnsNormally);
    });

    test('세션이 null이면 refresh가 중지된다', () async {
      manager.startPeriodicRefresh();

      // null 세션을 emit
      mockAuthService.emitSession(null);
      await Future.delayed(const Duration(milliseconds: 50));

      // stopPeriodicRefresh가 호출되어 내부 구독이 취소됨
      // 이후 추가 emit을 해도 에러가 발생하지 않아야 함
      mockAuthService.emitSession(null);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('startPeriodicRefresh를 다시 호출하면 이전 구독을 취소한다', () {
      manager.startPeriodicRefresh();
      // 다시 호출해도 에러가 발생하지 않아야 함 (내부에서 stopPeriodicRefresh 호출)
      expect(() => manager.startPeriodicRefresh(), returnsNormally);
    });
  });
}
