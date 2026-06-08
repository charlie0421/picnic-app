# Android device_hash → SSAID 기반 (재설치 견딤) 설계

- 날짜: 2026-06-08
- 브랜치: `feat/android-ssaid-device-hash`
- 범위: **picnic_lib 클라이언트만.** 서버 / DB / edge-function 무변경.

## 배경 / 문제

anti-abuse 의 device 코호트 신호는 `request_ip_log.device_hash` 로 "한 기기에서 출석/광고한
distinct 계정 수" 를 센다. 그런데 현재 Android `device_hash` 는 두 단계의 약점이 있다.

1. **(이미 수정됨) build-metadata collision** — 과거 `device_hash` 는 `Build.*` 속성
   (model/manufacturer/fingerprint/host 등)만 SHA-256 한 값이라, 단말 고유 엔트로피가 0 이었다.
   같은 기종+펌웨어 단말은 글자 단위로 동일 → **동일 hash collision** → 보급 기종(갤럭시 A/S 등)에서
   남남 수백 명이 한 hash 로 붕괴. PR #44 에서 **flutter_secure_storage 에 저장한 UUID v4** 로 전환해 해소.

2. **(이번 대상) UUID 는 per-install, not per-device** — Android 는 앱 삭제 시 앱 저장소를 비우고,
   flutter_secure_storage 의 Keystore 키는 백업으로 복원되지 않는다. 즉 **재설치하면 새 UUID** 가 발급된다.
   → 운영자가 *계정마다 재설치* 하면 device 코호트가 아예 형성되지 않아 신호를 우회할 수 있다.
   (iOS 는 Keychain 이 재설치를 견뎌 이미 per-device 에 가깝다 — Android 한정 문제.)

## 정책 맥락 (바 A)

이 변경은 "다중계정 자체를 막는다" 가 아니다. 다중계정은 정책상 허용이며, device 코호트는
**노골적 단일-설치 운영자를 식별하는 soft triage 신호**로만 쓴다. 목표는 **best-effort 억지력** —
재설치 우회 비용을 올리되 완벽 차단은 추구하지 않는다. enforce 의 진짜 무게는 ad_watch 사기 신호에 둔다.
(서버측 cohort 정책 변경 — IP-cluster→suspect, IP-집중 collision 필터 — 은 **별도 spec**.)

## 해결책

Android `device_hash` 를 **`Settings.Secure.ANDROID_ID`(SSAID) 의 SHA-256** 으로 산출한다.
SSAID 는 OS 가 랜덤 시드로 발급하는 (앱 서명키 × 사용자 × 기기) 고유값으로,
**재설치·업데이트해도 유지**(공장초기화에서만 리셋)되고 기종/펌웨어에서 파생되지 않아 **collision 이 없다**.
SSAID 가 없거나(에뮬레이터 등) 무효이면 기존 UUID 흐름으로 폴백한다.

> 아이러니하게도 SSAID 는 원래 코드의 `androidId` 필드가 담았어야 할 값이다 (현재는 `Build.FINGERPRINT`
> 가 잘못 들어가 있음). 이번 변경은 "UUID 우회" 가 아니라 원래 의도된 식별자를 올바르게 쓰는 것이다.

## 컴포넌트 변경

### 1. `picnic_lib/pubspec.yaml`
- `android_id` 패키지 추가 (Dart 한 줄로 SSAID 획득, 네이티브 코드 0).

### 2. `picnic_lib/lib/core/utils/device_fingerprint_helper.dart` (순수 헬퍼)
테스트 가능한 순수 함수 2개 추가:

- `static String? normalizeAndroidId(String? ssaid)`
  - 먼저 trim + 소문자화
  - `null` / 빈 문자열 → `null`
  - 알려진 불량 상수 `9774d56d682e549c` → `null`
  - hex 형태(`^[0-9a-f]+$`)가 아니거나 길이가 너무 짧으면(`< 8`, junk 가드) → `null`
    - SSAID 는 통상 16자 hex 지만 leading-zero 등으로 짧게 렌더될 수 있어 길이 상한을 강제하지 않는다 (유효값 over-reject 방지).
  - 통과 시 정규화된(소문자) 값 반환
- `static String hashAndroidId(String normalizedSsaid)`
  - `sha256("picnic.android_id:" + normalizedSsaid)` 의 hex 문자열 반환
  - 네임스페이스 prefix 로 raw SSAID 역산/타시스템 상관 방지. 기존 `generateHash` 의 sha256 유틸 재사용.

### 3. `picnic_lib/lib/core/utils/device_fingerprint.dart`
`getDeviceId()` 우선순위 변경:

```
Android:
  ssaid = await const AndroidId().getId()
  norm  = DeviceFingerprintHelper.normalizeAndroidId(ssaid)
  if norm != null:
      return DeviceFingerprintHelper.hashAndroidId(norm)   // 저장 안 함, 재계산해도 동일
  // norm == null → 아래 UUID 흐름으로 폴백
iOS (그리고 Android SSAID 폴백):
  v2 UUID 키 있으면 → 반환
  legacy 키 있으면 → 새 UUID 발급 + legacy 삭제
  둘 다 없으면 → fresh UUID
```

핵심 결정:
- **SSAID 가 stored UUID 보다 우선.** 안 그러면 기존 Android 유저가 옛 UUID 에 영구 고정돼 업그레이드되지 않는다.
- SSAID-hash 는 **저장하지 않는다.** 결정적이라 매 호출 재계산해도 같은 값이고, 저장하지 않으므로 재설치와 무관하게 동일하다.
- 기존 stored UUID 는 삭제하지 않고 **SSAID-null 폴백 안전망**으로 남긴다 (SSAID 가 일시적으로 null 일 때 hash 가 튀지 않도록).

### 4. `reset()` / `verify()`
- `verify()` 는 `getDeviceId()` 를 호출하므로 자동으로 새 로직을 탄다.
- `reset()` 은 저장된 키만 지운다. SSAID 기반 id 는 저장값이 아니므로 reset 후에도 동일하다
  (= 기기 신원은 "리셋" 대상이 아니라는 의도된 동작). 이 동작을 주석으로 명시한다.

## 엣지 케이스

| 상황 | 동작 |
|---|---|
| SSAID `null` (에뮬레이터/일부 환경) | UUID 폴백 |
| SSAID == `9774d56d682e549c` (구형 불량) | 무효 처리 → UUID 폴백 |
| 앱 서명키 변경 (재서명) | SSAID 변경됨 → device_hash 변경 (정상 릴리스에선 비발생) |
| 공장초기화 | 새 SSAID (best-effort 의 천장, 수용) |

## 롤아웃 / 마이그레이션

- 첫 실행 시 유효 SSAID 가 있는 Android 유저는 `device_hash` 가 **UUID → SSAID-hash 로 1회 변경**된다.
  cohort 가 1회 재흩어지지만 attendance 는 매일 1회라 1~2일 내 재형성된다. 기존 24h 차단은 자연 만료.
- 서버 / DB / edge-fn 무변경 — `request_ip_log` 가 더 안정적인 device_hash 값을 받기 시작할 뿐이다.
- ⚠️ **`android_id` 는 네이티브 구현을 포함한 플러그인** → **Shorebird 패치 불가, 스토어 릴리스 필요**
  (참고: Shorebird 패치는 Dart-only 변경만 가능. 새 네이티브 플러그인 추가는 full release build 대상).

## 테스트

- `DeviceFingerprintHelper` 의 두 신규 함수에 **순수 단위테스트**:
  - `normalizeAndroidId`: null / 빈값 / 불량상수 / 유효값 / 대문자→소문자 정규화 / 비-hex 거부
  - `hashAndroidId`: 결정성(같은 입력 → 같은 hash), 네임스페이스 prefix 반영, 길이 64 hex
- `getDeviceId()` 글루는 얇게 유지 — 분기/검증 로직은 전부 순수 헬퍼에. (플러그인+저장소 의존이라
  end-to-end 는 수동/통합 검증 대상.)

## Out of scope (YAGNI)

- 서버 cohort 정책 변경 (IP-cluster → suspect, IP-집중 collision 필터) — **별도 spec.**
- dead build-hash 경로(`_generateFingerprint`) 제거 — 선택적 정리, 이번 범위 아님.
- Play Integrity / 하드웨어 attestation 등 강한 per-device 신원 — 기각 (best-effort 기조).
- iOS 변경 — 불필요 (Keychain UUID 가 이미 재설치 견딤).
- install UUID 를 "재설치 횟수" 사기 신호로 별도 전송 — Client+Server 안에서 기각.

## 성공 기준

- 유효 SSAID 단말: 앱 **재설치 후에도 동일한 `device_hash`** 산출.
- 같은 기종+펌웨어의 *서로 다른* 단말: **서로 다른 `device_hash`** (collision 없음).
- SSAID 무효 단말: 기존 UUID 동작으로 회귀 (회귀 없음).
- 순수 헬퍼 단위테스트 그린.
