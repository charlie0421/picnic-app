# Android SSAID device_hash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Android `device_hash` 를 재설치를 견디는 `Settings.Secure.ANDROID_ID`(SSAID) 기반으로 바꿔, device 코호트 신호의 재설치-우회를 줄인다.

**Architecture:** client-only 변경. 순수 헬퍼(`DeviceFingerprintHelper`)에 SSAID 검증·해싱 함수를 추가해 단위테스트로 고정하고, `DeviceFingerprint.getDeviceId()` 는 Android 에서 SSAID 를 우선 사용하고 무효 시 기존 UUID 흐름으로 폴백하는 얇은 글루만 둔다. 서버/DB/edge-fn 무변경.

**Tech Stack:** Flutter / Dart, `android_id` 플러그인, `crypto`(SHA-256), `flutter_secure_storage`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-06-08-android-ssaid-device-hash-design.md`

**Worktree:** `~/Repositories/picnic-app-android-ssaid` (branch `feat/android-ssaid-device-hash`)

---

## File Structure

- `picnic_lib/pubspec.yaml` — `android_id` 의존성 추가
- `picnic_lib/lib/core/utils/device_fingerprint_helper.dart` — 순수 함수 `normalizeAndroidId`, `hashAndroidId` 추가
- `picnic_lib/lib/core/utils/device_fingerprint.dart` — `getDeviceId()` Android 분기 + 기존 UUID 로직을 `_getOrCreateUuid()` 로 추출
- `picnic_lib/test/core/utils/device_fingerprint_helper_test.dart` — 신규 함수 단위테스트 추가

작업 순서: 의존성 → 순수 헬퍼(TDD) → 글루 → 수동 검증.

---

### Task 1: `android_id` 의존성 추가

**Files:**
- Modify: `picnic_lib/pubspec.yaml` (dependencies 섹션, `device_info_plus:` 인근)

- [ ] **Step 1: 의존성 추가**

`picnic_lib/` 에서 실행 (최신 호환 버전 자동 해결):

```bash
cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter pub add android_id
```

Expected: `pubspec.yaml` 의 dependencies 에 `android_id: ^x.y.z` 가 추가되고 `flutter pub get` 이 성공.

- [ ] **Step 2: 해결 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && grep android_id pubspec.yaml`
Expected: `  android_id: ^...` 한 줄 출력.

- [ ] **Step 3: Commit**

```bash
cd ~/Repositories/picnic-app-android-ssaid
git add picnic_lib/pubspec.yaml picnic_lib/pubspec.lock
git commit -m "chore(device-fingerprint): add android_id dependency for SSAID"
```

---

### Task 2: `normalizeAndroidId` 순수 함수 (TDD)

SSAID 문자열을 검증·정규화한다. 무효이면 `null`.

**Files:**
- Test: `picnic_lib/test/core/utils/device_fingerprint_helper_test.dart`
- Modify: `picnic_lib/lib/core/utils/device_fingerprint_helper.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`device_fingerprint_helper_test.dart` 의 `group('DeviceFingerprintHelper', () { ... })` 안에 아래 그룹을 추가:

```dart
    group('normalizeAndroidId', () {
      test('returns null for null input', () {
        expect(DeviceFingerprintHelper.normalizeAndroidId(null), isNull);
      });

      test('returns null for empty / whitespace input', () {
        expect(DeviceFingerprintHelper.normalizeAndroidId(''), isNull);
        expect(DeviceFingerprintHelper.normalizeAndroidId('   '), isNull);
      });

      test('returns null for known-bad constant 9774d56d682e549c', () {
        expect(
          DeviceFingerprintHelper.normalizeAndroidId('9774d56d682e549c'),
          isNull,
        );
        // 대문자로 와도 정규화 후 동일하게 거부
        expect(
          DeviceFingerprintHelper.normalizeAndroidId('9774D56D682E549C'),
          isNull,
        );
      });

      test('returns null for non-hex input', () {
        expect(DeviceFingerprintHelper.normalizeAndroidId('xyz123hello'), isNull);
      });

      test('returns null for too-short input (< 8 chars)', () {
        expect(DeviceFingerprintHelper.normalizeAndroidId('a1b2'), isNull);
      });

      test('lowercases and returns a valid 16-hex SSAID', () {
        expect(
          DeviceFingerprintHelper.normalizeAndroidId('ABCDEF0123456789'),
          'abcdef0123456789',
        );
      });

      test('trims surrounding whitespace before validating', () {
        expect(
          DeviceFingerprintHelper.normalizeAndroidId('  dca8e4f1b2c3d4e5  '),
          'dca8e4f1b2c3d4e5',
        );
      });
    });
```

- [ ] **Step 2: 실패 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter test test/core/utils/device_fingerprint_helper_test.dart`
Expected: FAIL — `The method 'normalizeAndroidId' isn't defined for the type 'DeviceFingerprintHelper'`.

- [ ] **Step 3: 최소 구현**

`device_fingerprint_helper.dart` 의 `class DeviceFingerprintHelper {` 안에 추가 (`generateHash` 아래 권장):

```dart
  /// 알려진 불량 SSAID 상수 — 일부 구형 단말이 하드코딩 반환하던 값.
  static const String _badAndroidId = '9774d56d682e549c';
  static final RegExp _hexOnly = RegExp(r'^[0-9a-f]+$');

  /// SSAID(Settings.Secure.ANDROID_ID) 를 검증·정규화한다.
  ///
  /// 규칙: trim + 소문자화 → 빈값 / 불량상수 / 비-hex / 8자 미만은 무효(null).
  /// SSAID 는 통상 16자 hex 지만 leading-zero 등으로 짧게 렌더될 수 있어
  /// 상한은 강제하지 않는다(유효값 over-reject 방지).
  static String? normalizeAndroidId(String? ssaid) {
    if (ssaid == null) return null;
    final v = ssaid.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == _badAndroidId) return null;
    if (v.length < 8) return null;
    if (!_hexOnly.hasMatch(v)) return null;
    return v;
  }
```

- [ ] **Step 4: 통과 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter test test/core/utils/device_fingerprint_helper_test.dart`
Expected: PASS (전체 그린).

- [ ] **Step 5: Commit**

```bash
cd ~/Repositories/picnic-app-android-ssaid
git add picnic_lib/lib/core/utils/device_fingerprint_helper.dart picnic_lib/test/core/utils/device_fingerprint_helper_test.dart
git commit -m "feat(device-fingerprint): add normalizeAndroidId validator"
```

---

### Task 3: `hashAndroidId` 순수 함수 (TDD)

정규화된 SSAID 를 네임스페이스 prefix 와 함께 SHA-256 해싱.

**Files:**
- Test: `picnic_lib/test/core/utils/device_fingerprint_helper_test.dart`
- Modify: `picnic_lib/lib/core/utils/device_fingerprint_helper.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

같은 테스트 파일에 그룹 추가 (파일 상단에 이미 `import 'dart:convert';` 와 `import 'package:crypto/crypto.dart';` 존재 — 그대로 사용):

```dart
    group('hashAndroidId', () {
      test('is deterministic for the same input', () {
        final a = DeviceFingerprintHelper.hashAndroidId('abcdef0123456789');
        final b = DeviceFingerprintHelper.hashAndroidId('abcdef0123456789');
        expect(a, b);
      });

      test('returns a 64-char lowercase hex string', () {
        final h = DeviceFingerprintHelper.hashAndroidId('abcdef0123456789');
        expect(h.length, 64);
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h), isTrue);
      });

      test('equals SHA-256 of the namespaced string', () {
        const id = 'abcdef0123456789';
        final expected =
            sha256.convert(utf8.encode('picnic.android_id:$id')).toString();
        expect(DeviceFingerprintHelper.hashAndroidId(id), expected);
      });

      test('namespace makes it differ from a raw SHA-256 of the id', () {
        const id = 'abcdef0123456789';
        final raw = sha256.convert(utf8.encode(id)).toString();
        expect(DeviceFingerprintHelper.hashAndroidId(id), isNot(raw));
      });
    });
```

- [ ] **Step 2: 실패 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter test test/core/utils/device_fingerprint_helper_test.dart`
Expected: FAIL — `The method 'hashAndroidId' isn't defined`.

- [ ] **Step 3: 최소 구현**

`device_fingerprint_helper.dart` 의 클래스 안에 추가 (`normalizeAndroidId` 아래):

```dart
  /// device_hash 네임스페이스 prefix — raw SSAID 역산/타시스템 상관 방지.
  static const String _androidIdNamespace = 'picnic.android_id:';

  /// 정규화된 SSAID 를 네임스페이스와 함께 SHA-256 한 64-hex 문자열 반환.
  /// 입력은 [normalizeAndroidId] 를 통과한 값이어야 한다.
  static String hashAndroidId(String normalizedSsaid) {
    final bytes = utf8.encode('$_androidIdNamespace$normalizedSsaid');
    return sha256.convert(bytes).toString();
  }
```

- [ ] **Step 4: 통과 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter test test/core/utils/device_fingerprint_helper_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/Repositories/picnic-app-android-ssaid
git add picnic_lib/lib/core/utils/device_fingerprint_helper.dart picnic_lib/test/core/utils/device_fingerprint_helper_test.dart
git commit -m "feat(device-fingerprint): add namespaced hashAndroidId"
```

---

### Task 4: `getDeviceId()` Android SSAID 분기

기존 UUID 로직을 `_getOrCreateUuid()` 로 추출하고, Android 에서 유효 SSAID 가 있으면 그 해시를 우선 반환.

**Files:**
- Modify: `picnic_lib/lib/core/utils/device_fingerprint.dart`

- [ ] **Step 1: import 추가**

`device_fingerprint.dart` 상단 import 블록에 추가:

```dart
import 'package:android_id/android_id.dart';
```

- [ ] **Step 2: 기존 UUID 로직을 `_getOrCreateUuid()` 로 추출**

현재 `getDeviceId()` 본문(우선순위 1~3: v2 키 → legacy 마이그레이션 → fresh)을 그대로 새 private 메서드로 옮긴다. 클래스 안에 추가:

```dart
  /// v2 UUID 우선 → legacy 강제 마이그레이션 → fresh UUID.
  /// (Android SSAID 무효 시 폴백, iOS 기본 경로.)
  static Future<String> _getOrCreateUuid() async {
    final uuid = await _storage.read(key: _uuidVersionKey);
    if (uuid != null && uuid.isNotEmpty) {
      return uuid;
    }

    final legacy = await _storage.read(key: _fingerprintKey);
    if (legacy != null && legacy.isNotEmpty) {
      final migrated = _uuidGen.v4();
      await _storage.write(key: _uuidVersionKey, value: migrated);
      await _storage.delete(key: _fingerprintKey);
      return migrated;
    }

    final fresh = _uuidGen.v4();
    await _storage.write(key: _uuidVersionKey, value: fresh);
    return fresh;
  }
```

- [ ] **Step 3: `getDeviceId()` 를 Android 분기 + 폴백으로 교체**

`getDeviceId()` 본문 전체를 아래로 교체 (doc 주석은 유지/보강):

```dart
  /// 기기 식별자.
  ///
  /// Android: SSAID(Settings.Secure.ANDROID_ID) 가 유효하면 그 해시를 우선 반환한다.
  ///   - SSAID 는 재설치/업데이트를 견디고(공장초기화만 리셋) 기종/펌웨어에서 파생되지
  ///     않아 collision 이 없다. stored UUID 보다 우선해야 기존 유저도 업그레이드된다.
  ///   - 해시는 저장하지 않는다(결정적이라 재계산해도 동일). SSAID 무효(에뮬레이터 등)면
  ///     기존 UUID 흐름으로 폴백한다.
  /// iOS: 기존 UUID 흐름(Keychain 이 재설치를 견딤).
  static Future<String> getDeviceId() async {
    if (UniversalPlatform.isAndroid) {
      final ssaid = await const AndroidId().getId();
      final norm = DeviceFingerprintHelper.normalizeAndroidId(ssaid);
      if (norm != null) {
        return DeviceFingerprintHelper.hashAndroidId(norm);
      }
      // SSAID 무효 → 아래 UUID 폴백
    }
    return _getOrCreateUuid();
  }
```

- [ ] **Step 4: 정적 분석 + 기존 테스트 회귀 확인**

Run:
```bash
cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter analyze lib/core/utils/device_fingerprint.dart && flutter test test/core/utils/device_fingerprint_test.dart test/core/utils/device_fingerprint_helper_test.dart
```
Expected: analyze 무경고(신규 import 사용됨), 기존 `device_fingerprint_test.dart` 그린(회귀 없음).

- [ ] **Step 5: Commit**

```bash
cd ~/Repositories/picnic-app-android-ssaid
git add picnic_lib/lib/core/utils/device_fingerprint.dart
git commit -m "feat(device-fingerprint): use SSAID-based hash on Android, UUID fallback"
```

---

### Task 5: 수동/통합 검증 (플랫폼 채널 의존이라 단위테스트 불가)

**Files:** 없음 (검증 전용)

- [ ] **Step 1: 실기기(Android) 에서 동작 확인**

Run: `cd ~/Repositories/picnic-app-android-ssaid && flutter run --dart-define=DISABLE_VM_CHECK=true`
- `DeviceFingerprint.getDeviceId()` 가 64-hex 를 반환하는지(로그/디버거).
- 앱 **삭제 후 재설치** → 같은 값이 나오는지 (SSAID 안정성).
- (가능하면) 같은 기종 다른 단말 → 다른 값이 나오는지.

- [ ] **Step 2: 에뮬레이터 폴백 확인**

에뮬레이터(SSAID null 가능)에서 실행 → 크래시 없이 UUID 값으로 폴백되는지 확인.

- [ ] **Step 3: 전체 테스트 스위트**

Run: `cd ~/Repositories/picnic-app-android-ssaid/picnic_lib && flutter test`
Expected: 전체 그린.

---

## 릴리스 주의 (구현과 별개, 배포 시)

- `android_id` 는 네이티브 구현 포함 플러그인 → **Shorebird 패치 불가, 스토어 릴리스 필요** (`picnic-v*` 태그 트리거). Dart-only 가 아니므로 patch 로 내보낼 수 없음.
- 롤아웃 시 Android 유저 device_hash 가 UUID→SSAID-hash 로 1회 변경 → cohort 1회 재흩어짐(attendance 매일이라 1~2일 재형성). 서버 무변경.

## Out of scope

- 서버 cohort 정책 변경(IP-cluster→suspect, IP-집중 collision 필터) — 별도 spec/plan.
- dead build-hash 경로(`_generateFingerprint`) 제거 — 선택적.
- iOS 변경 없음.
