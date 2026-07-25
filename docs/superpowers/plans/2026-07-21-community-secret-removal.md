# 커뮤니티 비밀키 제거 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 비활성화된 커뮤니티 코드를 보존하면서 앱 asset에서 AWS·DeepL·YouTube 비밀값을 제거하고, 빈 자격증명으로 외부 요청이 발생하지 않게 한다.

**Architecture:** 기존 JSON 설정 키와 호출 UI는 유지한다. 설정 회귀 테스트가 번들 파일의 민감값을 차단하고, 각 연동 서비스는 네트워크 작업 직전에 공백 제거 기반 자격증명 검사를 수행한다. S3와 DeepL은 명시적인 `StateError`로 종료하고 YouTube는 기존 fallback 모델을 반환한다.

**Tech Stack:** Flutter 3.41, Dart 3.11, `flutter_test`, `http`, 기존 `picnic_app`/`picnic_lib` 패키지

## Global Constraints

- `ttja_app`은 수정하거나 검증 대상으로 포함하지 않는다.
- 커뮤니티 소스 코드와 관련 의존성을 삭제하지 않는다.
- Supabase Edge Function을 새로 만들지 않는다.
- `supabase.anon_key`, Firebase 설정, OAuth client ID, 광고 SDK ID는 변경하지 않는다.
- `storage.aws.access_key_id`, `storage.aws.secret_access_key`, `api_keys.deepl`, `api_keys.youtube` 키의 JSON 스키마는 유지하고 값만 빈 문자열로 만든다.
- 자격증명 값은 테스트 출력, 예외 메시지, 로그에 포함하지 않는다.
- 프로덕션 코드 변경 전에 해당 동작을 검증하는 실패 테스트를 먼저 실행한다.

---

### Task 1: 번들 설정 비밀값 회귀 방지

**Files:**
- Create: `picnic_app/test/config_secrets_test.dart`
- Modify: `picnic_app/config/dev.json`
- Modify: `picnic_app/config/local.json`
- Modify: `picnic_app/config/prod.json`

**Interfaces:**
- Consumes: `dart:convert`, `dart:io`, 각 환경 JSON의 기존 중첩 키
- Produces: 네 민감 경로가 모든 번들 환경에서 빈 문자열임을 보장하는 테스트

- [ ] **Step 1: 실패하는 설정 회귀 테스트 작성**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const environments = ['dev', 'local', 'prod'];

  for (final environment in environments) {
    test('$environment 설정은 장기 비밀키를 번들하지 않는다', () async {
      final file = File('config/$environment.json');
      final config = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final storage = config['storage'] as Map<String, dynamic>;
      final aws = storage['aws'] as Map<String, dynamic>;
      final apiKeys = config['api_keys'] as Map<String, dynamic>;

      expect(
        (aws['access_key_id'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment AWS access key must not be bundled',
      );
      expect(
        (aws['secret_access_key'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment AWS secret key must not be bundled',
      );
      expect(
        (apiKeys['deepl'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment DeepL key must not be bundled',
      );
      expect(
        (apiKeys['youtube'] as String).trim().isEmpty,
        isTrue,
        reason: '$environment YouTube key must not be bundled',
      );
    });
  }
}
```

- [ ] **Step 2: 테스트가 기존 비밀값 때문에 실패하는지 확인**

Run: `cd picnic_app && flutter test test/config_secrets_test.dart`

Expected: 세 환경 중 첫 실행에서 `Expected: true`, `Actual: false`로 FAIL하며 실제 값은 출력하지 않는다.

- [ ] **Step 3: 세 JSON 파일의 네 민감값을 빈 문자열로 교체**

```json
"access_key_id": "",
"secret_access_key": ""
```

```json
"youtube": "",
"deepl": ""
```

- [ ] **Step 4: 설정 회귀 테스트 통과 확인**

Run: `cd picnic_app && flutter test test/config_secrets_test.dart`

Expected: `+3: All tests passed!`

- [ ] **Step 5: 변경 커밋**

```bash
git add picnic_app/test/config_secrets_test.dart picnic_app/config/dev.json picnic_app/config/local.json picnic_app/config/prod.json
git commit -m "security: remove bundled community credentials"
```

### Task 2: S3와 DeepL의 빈 자격증명 차단

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/ui/s3_uploader_test.dart`
- Modify: `picnic_lib/lib/presentation/widgets/ui/s3_uploader.dart`
- Modify: `picnic_lib/test/core/utils/deepl_translate_service_test.dart`
- Modify: `picnic_lib/lib/core/utils/deepl_translate_service.dart`

**Interfaces:**
- Consumes: `S3Uploader.uploadFile`, `DeepLTranslationService.translateText`
- Produces: 자격증명이 없을 때 `StateError('Community integration is disabled')`를 발생시키는 공통 동작

- [ ] **Step 1: S3 빈 자격증명 실패 테스트 작성**

```dart
test('빈 자격증명은 파일 처리 전에 업로드를 거부한다', () async {
  final uploader = S3Uploader(
    accessKey: ' ',
    secretKey: '',
    region: 'ap-northeast-2',
    bucketName: 'bucket',
  );

  await expectLater(
    uploader.uploadFile('post/image', Object(), (_) {}),
    throwsA(
      isA<StateError>().having(
        (error) => error.message,
        'message',
        'Community integration is disabled',
      ),
    ),
  );
});
```

- [ ] **Step 2: S3 테스트가 잘못된 파일 형식 오류로 실패하는지 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/ui/s3_uploader_test.dart`

Expected: 새 테스트가 원하는 `StateError`가 아닌 기존 파일 처리 오류로 FAIL한다.

- [ ] **Step 3: S3 요청 시작부에 최소 검사 구현**

```dart
void _ensureCredentialsAvailable() {
  if (accessKey.trim().isEmpty || secretKey.trim().isEmpty) {
    throw StateError('Community integration is disabled');
  }
}
```

`uploadFile`의 첫 실행문에서 `_ensureCredentialsAvailable()`를 호출한다.

- [ ] **Step 4: S3 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/ui/s3_uploader_test.dart`

Expected: 모든 테스트 PASS.

- [ ] **Step 5: DeepL 빈 자격증명 실패 테스트 작성**

```dart
test('빈 API 키는 번역 요청 전에 거부한다', () async {
  final disabledService = DeepLTranslationService(apiKey: ' ');

  await expectLater(
    disabledService.translateText('안녕하세요', 'KO', 'EN'),
    throwsA(
      isA<StateError>().having(
        (error) => error.message,
        'message',
        'Community integration is disabled',
      ),
    ),
  );
});
```

- [ ] **Step 6: DeepL 테스트가 재시도 후 원문 반환으로 실패하는지 확인**

Run: `cd picnic_lib && flutter test test/core/utils/deepl_translate_service_test.dart`

Expected: 새 테스트가 `StateError` 대신 기존 원문 반환 동작 때문에 FAIL한다.

- [ ] **Step 7: DeepL 요청 전에 최소 검사 구현**

```dart
final String _apiKey;

DeepLTranslationService({required String apiKey, this.debugMode = true})
    : _apiKey = apiKey,
      _deepl = DeepL(authKey: apiKey);

void _ensureCredentialsAvailable() {
  if (_apiKey.trim().isEmpty) {
    throw StateError('Community integration is disabled');
  }
}
```

`translateText`의 retry loop 전에 `_ensureCredentialsAvailable()`를 호출한다.

- [ ] **Step 8: DeepL 및 S3 집중 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/core/utils/deepl_translate_service_test.dart test/presentation/widgets/ui/s3_uploader_test.dart`

Expected: 모든 테스트 PASS.

- [ ] **Step 9: 변경 커밋**

```bash
git add picnic_lib/lib/presentation/widgets/ui/s3_uploader.dart picnic_lib/test/presentation/widgets/ui/s3_uploader_test.dart picnic_lib/lib/core/utils/deepl_translate_service.dart picnic_lib/test/core/utils/deepl_translate_service_test.dart
git commit -m "security: block disabled community integrations"
```

### Task 3: 모바일 YouTube API의 키 없는 fallback

**Files:**
- Modify: `picnic_lib/test/core/services/youtube_service_helper_test.dart`
- Modify: `picnic_lib/lib/core/services/youtube_service.dart`

**Interfaces:**
- Consumes: `YouTubeContentService.fetchYoutubeInfo`, `http.Client`
- Produces: `YouTubeContentService.test({required http.Client httpClient, required String Function() apiKeyProvider})`; YouTube 키가 비어 있으면 Google API를 호출하지 않고 `createFallbackVideoInfo(url)`를 반환하는 네이티브 경로

- [ ] **Step 1: 키가 없을 때 fallback을 반환하는 실패 테스트 작성**

```dart
import 'package:http/testing.dart';

test('native service returns fallback when YouTube API key is empty', () async {
  var requestCount = 0;
  final service = YouTubeContentService.test(
    httpClient: MockClient((request) async {
      requestCount++;
      throw StateError('HTTP request must not be sent');
    }),
    apiKeyProvider: () => ' ',
  );

  final result = await service.fetchYoutubeInfo(
    'https://www.youtube.com/watch?v=abc123',
  );

  expect(result.id, 'abc123');
  expect(result.title, 'YouTube Video');
  expect(result.viewCount, 0);
  expect(requestCount, 0);
});
```

- [ ] **Step 2: 테스트가 Google API 요청 경로 진입으로 실패하는지 확인**

Run: `cd picnic_lib && flutter test test/core/services/youtube_service_helper_test.dart --plain-name "native service returns fallback when YouTube API key is empty"`

Expected: `YouTubeContentService.test` 생성자가 존재하지 않아 컴파일 FAIL한다.

- [ ] **Step 3: 테스트 가능한 요청 경계와 빈 키 fallback 구현**

```dart
final http.Client _httpClient;
final String Function() _apiKeyProvider;

YouTubeContentService._internal()
    : _httpClient = http.Client(),
      _apiKeyProvider = (() => Environment.youtubeApiKey);

@visibleForTesting
YouTubeContentService.test({
  required http.Client httpClient,
  required String Function() apiKeyProvider,
})  : _httpClient = httpClient,
      _apiKeyProvider = apiKeyProvider;

final apiKey = _apiKeyProvider().trim();
if (apiKey.isEmpty) {
  return createFallbackVideoInfo(url);
}
```

Google API URL을 구성하기 전에 위 검사를 두고, 두 `http.get` 호출을 `_httpClient.get`으로 교체한다. 기본 factory singleton 동작은 유지한다.

- [ ] **Step 4: YouTube 집중 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/core/services/youtube_service_helper_test.dart`

Expected: 모든 테스트 PASS.

- [ ] **Step 5: 변경 커밋**

```bash
git add picnic_lib/lib/core/services/youtube_service.dart picnic_lib/test/core/services/youtube_service_helper_test.dart
git commit -m "security: disable native YouTube API without key"
```

### Task 4: 통합 검증 및 문서 정합성

**Files:**
- Modify only if verification reveals a regression in files changed by Tasks 1–3.

**Interfaces:**
- Consumes: Tasks 1–3의 설정과 서비스 동작
- Produces: 집중 테스트 결과, 분석 결과, 비밀값 재탐지 결과

- [ ] **Step 1: 비밀값 길이 검사**

Run: `for f in picnic_app/config/dev.json picnic_app/config/local.json picnic_app/config/prod.json; do jq -e '(.storage.aws.access_key_id | length) == 0 and (.storage.aws.secret_access_key | length) == 0 and (.api_keys.deepl | length) == 0 and (.api_keys.youtube | length) == 0' "$f"; done`

Expected: 세 파일 모두 `true`, exit 0.

- [ ] **Step 2: 전체 영향 테스트 실행**

Run: `cd picnic_app && flutter test test/config_secrets_test.dart`

Expected: PASS.

Run: `cd picnic_lib && flutter test test/core/utils/deepl_translate_service_test.dart test/core/services/youtube_service_helper_test.dart test/presentation/widgets/ui/s3_uploader_test.dart`

Expected: PASS.

- [ ] **Step 3: 정적 분석 실행**

Run: `cd picnic_app && flutter analyze`

Expected: 기존 integration test의 Riverpod `Override` 오류 등 기준선 이슈는 별도 보고하되, Tasks 1–3이 새 오류를 추가하지 않는다.

Run: `cd picnic_lib && flutter analyze`

Expected: 기존 분석 부채는 별도 보고하되, Tasks 1–3이 새 오류를 추가하지 않는다.

- [ ] **Step 4: 변경 범위 및 작업 트리 확인**

Run: `git diff --check && git status --short && git log -5 --oneline`

Expected: 공백 오류 없음. 변경 파일은 명세·계획 및 Tasks 1–3 범위로 제한된다.

- [ ] **Step 5: 운영 후속 조치 보고**

완료 보고에 AWS, DeepL, YouTube 콘솔에서 기존 자격증명을 폐기해야 한다는 점을 명시한다. 실제 키 값은 보고서에 포함하지 않는다.
