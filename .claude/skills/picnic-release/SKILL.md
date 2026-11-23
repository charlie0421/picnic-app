---
name: picnic-release
description: picnic_app 스토어 신규 바이너리를 릴리스할 때 사용한다 — "릴리즈 해줘", "새 버전 업로드", "빌드넘버만 올려서 다시 빌드", "실패한 Codemagic 빌드 재시도", "picnic-v 태그 푸시". 인자는 patch(새 버전) · build(현재 버전의 새 바이너리) · M.m.P+MmPPBB(직접 지정). 업로드된 빌드를 스토어에 내보내는 출시("출시해줘", "심사 올려줘", "production 으로 올려줘", "배포 비율 올려줘")도 맡는다. Shorebird OTA 패치, 스테이징 빌드, ttja_app 에는 쓰지 않는다.
argument-hint: "[patch | build | <M.m.P+MmPPBB> | promote <M.m.P+MmPPBB>]"
---

# picnic_app 신규 바이너리 릴리스

최신 `origin/main` 에 버전 범프를 머지하고, 그 커밋에 `picnic-v<버전>` 태그를 푸시해
Codemagic iOS/Android 프로덕션 빌드를 시작한다. 기계적 단계는 `scripts/release_picnic.sh` 가 맡는다.

**선독 필수:** `~/.config/ai-agent-policies/flutter-release.md` (MmPPBB 규칙·승인 게이트의 원본).

## 모드

| 호출 | 뜻 | 버전 |
|---|---|---|
| `patch` | **새로운 버전** — 패치 버전만 올린다 | `next patch` · 1.3.5+130501 → 1.3.6+130601 |
| `build` | **현재 버전의 새 바이너리** — 빌드 번호만 올린다 (재빌드, 실패한 빌드 재시도) | `next build` · 1.3.5+130501 → 1.3.5+130502 |
| `<M.m.P+MmPPBB>` | **직접 지정** — minor·major 증가도 여기로 | 사용자 값 그대로 · 예 `1.4.0+140001` |

- 모드는 1번의 표에서 위부터 처음 맞는 줄로 정한다.
- 직접 지정은 `next` 를 건너뛰고 1번에서 그 값을 쓴다. `bump` 가 형식·MmPPBB 접두를 검증하고, 빌드 번호가
  원격 릴리스 태그(스테이징 포함)의 최댓값보다 큰지 본다. 거부될 때만 되묻는다.
- 범프하는 세 모드는 모두 아래 2~6을 거친다. `build` 도 범프 PR 을 생략하지 않는다(태그는 pubspec 과 일치해야 하고,
  커밋 하나에는 릴리스 태그가 하나만 붙을 수 있다).

## 절차

0. **최신 코드 받기** — 항상 여기서 시작한다. 이전 세션의 브랜치·로컬 `main`·기억 속 SHA 를 믿지 않는다.
   ```bash
   git fetch origin main --tags --prune
   prev=$(git describe --tags --abbrev=0 --match 'picnic-v*' origin/main)
   git log --oneline "$prev"..origin/main
   scripts/release_picnic.sh status "$prev"
   ```
   `git log` 출력(직전 릴리스 태그 이후 커밋)이 곧 이번 릴리스 내용이다 — 사용자에게 보여준다.
   사용자가 "머지했다"고 한 수정이 목록에 없으면 멈추고 PR 번호를 묻는다.
   `status` 출력은 직전 릴리스의 빌드 결과다. Codemagic API 든 GitHub 체크든 같은 열(워크플로 ID, 상태, 시작, 끝, URL)로
   최신순으로 나온다. `picnic-app-ios`·`picnic-app-android` 의 첫 줄이 모두 `finished` 면 성공이다. 하나라도
   `failed`·`canceled`·`timeout` 이면 실패다. `queued`·`building`·`in_progress` 같은 진행 상태면 끝난 뒤 다시 본다.
   두 워크플로 중 하나라도 줄이 없거나 위에 없는 값이면 성공으로 보지 않는다 — Codemagic 화면이나 `shorebird releases list`
   로 그 버전이 나갔는지 확인하고, 그래도 모르면 사용자에게 묻는다
1. **버전 결정** — 직접 지정이 아니면 `scripts/release_picnic.sh next <patch|build>` 를 실행한다. 아래 표에서 위부터 처음 맞는 줄을 따른다.

   | 상태 | 할 일 |
   |---|---|
   | 사용자가 버전을 직접 지정했다 | 그 값으로 2부터 진행한다. 표시 버전(예: 1.3.6)만 주면 그 버전 태그의 최대 빌드 순번 +1 을 붙인다(태그가 없으면 01) |
   | `next` 가 "아직 태그되지 않았다"로 멈췄다 | origin/main 의 버전이 이번 버전이다. 2~6을 건너뛰고 7로 간다 |
   | 0에서 직전 빌드가 실패했다 | `next build` 값으로 진행한다(같은 버전, 빌드 순번 +1) |
   | 그 밖 | 요청한 모드의 `next` 값으로 진행한다. 요청에 모드가 없으면 `patch` 다 |
2. **브랜치** — `git switch -c chore/release-<M>-<m>-<P>[-build-<BB>] origin/main --no-track`
   (워크트리 안에서만. 메인 폴더에서는 워크트리를 먼저 만든다.) 기존 릴리스 브랜치를 재사용하지 않고
   방금 받은 `origin/main` 에서 새로 만든다 — 아니면 `bump` 가 거부한다
3. **범프** — `scripts/release_picnic.sh bump <버전>` → 변경은 `picnic_app/pubspec.yaml` 한 줄이어야 한다
4. **가드 테스트** — `cd picnic_app && flutter test`. 끝난 뒤 `git status --short` 로 `pubspec.lock` 이 안 바뀌었는지 본다
5. **커밋·PR** — `chore(release): bump picnic to <버전>`. PR 본문에 0의 목록(직전 릴리스 태그 이후 PR)을 적는다
6. **머지** — squash. 한 줄 범프라 교차 리뷰는 생략한다
7. **태그 dry-run** — `scripts/release_picnic.sh tag [--skip-tests]` 가 다시 fetch 한 뒤 태그·버전·대상 커밋을 출력한다.
   대상 커밋이 6의 머지 커밋이 아니면(그 사이 다른 PR 이 머지됨) 추가된 커밋을 사용자에게 알린다
8. **사용자 승인** — 7의 출력을 보여주고 *전체 테스트 / `-skip-tests` / 보류* 중 고르게 한다. **"릴리즈 해줘" 는 이 승인이 아니다**
9. **푸시** — 승인된 옵션 그대로 `scripts/release_picnic.sh tag [--skip-tests] --push`
10. **시작 확인** — `scripts/release_picnic.sh status <tag>` 에 `picnic-app-ios`·`picnic-app-android` 가 둘 다 보여야 한다
11. **보고** — 아래 "완료의 정의" 대로

`-skip-tests` 는 `picnic_lib` 의 긴 커버리지 테스트 단계만 건너뛴다. 릴리스 가드 테스트는 항상 돈다.

## 완료의 정의

태그 푸시는 시작일 뿐이다. 보고할 때 확인한 것과 확인하지 않은 것을 나눠 적는다.

- 확인 대상: Codemagic 두 워크플로 `finished`/success → App Store Connect·Google Play 업로드 수신
  → `shorebird releases list` 에 새 전체 버전이 iOS·Android 모두 active
- iOS 약 20분, Android 약 1시간. 동시 빌드가 1개라 Android 는 iOS 가 끝날 때까지 `queued` 다 — 실패가 아니다
- 빌드가 도는 동안 세션을 붙잡고 기다리지 않는다. 시작 확인까지 보고하고, 나머지는 미확인으로 남긴다
- Jira 이슈를 `검토중` 으로 넘기지 않는다

## 출시 — 스토어 심사 제출·production

빌드(위 절차)와 출시는 분리돼 있다. 빌드는 TestFlight·Play internal 까지만 올린다. 사용자가 테스트 빌드를 확인한 뒤
출시를 요청하면 `scripts/release_picnic.sh promote` 가 Codemagic `picnic-app-promote` 를 API 로 시작한다.
스토어 인증은 Codemagic 이 가진 것을 쓴다. 로컬에는 `~/.config/picnic/codemagic.env` 만 있으면 된다.

| 플랫폼 | `--submit` 이 하는 일 |
|---|---|
| iOS | 빌드를 App Store 심사에 제출한다. 승인되면 모든 사용자에게 바로 출시된다(단계적 출시 없음) |
| Android | internal 의 같은 버전 코드를 production 트랙에 100% 로 설정한다. `--fraction` 은 사용자가 단계적 배포를 따로 요청할 때만 |

**출시 노트는 매번 같은 내용이다.** 스크립트가 직전 출시본의 노트를 그대로 복사한다 — iOS 는 출시 중 버전의 언어별
'새로운 기능', Android 는 production release 의 언어별 노트. 노트 파일이나 PR 은 없다. 문구를 바꾸려면 사용자가
App Store Connect·Play Console 에서 직전 출시본의 노트를 한 번 고친다. 그다음 출시부터 그 문구가 이어진다.

1. **대상 확인** — 대상 버전은 `picnic-v<버전>[-skip-tests]` 태그로 빌드가 끝난 것이어야 한다. 두 스크립트 모두 태그 이름이
   아니라 태그 커밋의 `pubspec.yaml` 로 대조하고, 같은 빌드 번호를 쓴 스테이징 태그가 있으면 거부한다.
   사용자가 확인한 빌드가 이 버전인지 묻는다(TestFlight·internal 에 이전 빌드가 함께 있다)
2. **check** — `scripts/release_picnic.sh promote <버전>`. 읽기 전용이며 머신 준비를 포함해 수 분 걸린다. 끝나면
   `Promote release` 로그를 출력한다. 로그에서 다음을 본다:
   - iOS 빌드가 `VALID` 이고 만료되지 않았다. 심사 중·출시 대기 중인 버전과 다른 버전의 초안이 없다
   - 복사할 출시 노트(`[언어] 문구` 줄). 빈 언어가 있거나 노트가 없으면 거부된다
   - Android internal 에 같은 버전 코드가 있고, production 에 더 높은 코드가 없다
   - 마지막 줄이 `check 통과` 다. `출시 불가` 면 그 아래 사유를 사용자에게 전하고 멈춘다
3. **사용자 승인** — 2의 결과(복사할 노트 포함)와 함께 *버전 · 플랫폼 · iOS 승인 즉시 전체 출시 · Android production 100%* 을
   보여주고 명시적 승인을 받는다. **"출시해줘" 는 이 승인이 아니다.** 강업은 이 승인에 포함되지 않는다
4. **submit** — 승인된 범위 그대로 `scripts/release_picnic.sh promote <버전> --submit [--platform ios|android] [--fraction <0~1>]`.
   시작 응답을 못 받았다는 오류면 다시 실행하기 전에 Codemagic 에서 실행이 생겼는지 먼저 본다(두 번 돌면 스토어에 두 번 쓴다)
5. **보고** — 확인한 것과 확인하지 않은 것을 나눈다. iOS 는 심사 제출까지가 확인이고, 승인·출시는 미확인이다.
   Android 는 production 설정 완료까지다. 이후 상태는 App Store Connect·Play Console 에서 본다

### 출시 뒤

- Android 비율 올리기: `promote <버전> --submit --platform android --fraction 0.5`. `--fraction` 을 빼면 100% 로 완료한다. 매번 3의 승인을 받는다
- 이미 제출한 iOS 버전에 단계적 출시가 걸려 있으면(예: 1.3.7 은 단계적으로 제출됐다) `promote <버전> --ios-release-now` 로 상태를 보고,
  승인을 받아 `--submit` 을 붙여 해제한다. 시작 전(INACTIVE)일 때만 해제한다. 이미 시작된 단계적 출시는 App Store Connect 에서 처리한다
- Google Play 서비스 계정에는 Play Console 의 production 출시 권한이 필요하다. 없으면 check 는 통과하고 submit 에서 `The caller does not have permission` 으로 실패한다
- iOS 가 거절되면 원인을 고친 뒤 같은 명령을 `--platform ios` 로 다시 실행한다. 편집 가능한 버전을 재사용한다
- 중간 실패는 로그 끝의 "이미 완료한 플랫폼 / 남은 플랫폼" 을 보고 남은 플랫폼만 다시 실행한다. 끝난 플랫폼을 다시 보내지 않는다
- 강업은 `picnic-force-update` 로 따로 결정한다. Jira 이슈를 `검토중` 으로 넘기지 않는다

## 빌드 실패 시

기존 태그를 삭제·이동·재푸시하지 않는다. 같은 커밋에 접미사만 바꾼 태그를 하나 더 붙이지도 않는다
(`resolve_release_tag.sh` 가 커밋당 태그 1개를 요구하고, 스토어는 빌드 번호 재사용을 거부한다).
원인을 고친 뒤 **`build` 모드로 처음부터** 다시 돈다. 코드 원인은 main 에 머지하고, CI 설정 원인(인증 토큰 등)은
Codemagic 에서 고친다. 그 사이 `patch` 범프가 main 에 머지됐고 아직 태그되지 않았으면, `bump` 에 실패한 버전의
다음 빌드 번호를 직접 지정해 되돌린다(예: 1.3.7+130701 → 1.3.6+130602).

## 흔한 실수

| 실수 | 바로잡기 |
|---|---|
| 로컬 `main` 을 체크아웃해 태그하려 함 | 워크트리에서는 불가능하고 불필요하다. 스크립트가 `origin/main` 커밋을 직접 태그한다 |
| 릴리스 브랜치 HEAD 에 태그 | squash 머지라 브랜치 커밋 ≠ main 커밋. 항상 `origin/main` |
| GitHub 체크에 Android 가 없어 실패로 판단 | 체크는 빌드가 시작돼야 생긴다. `status` (Codemagic API) 로 `queued` 를 확인 |
| 이 절차로 OTA 를 내보냄 | OTA 는 태그 없이 Codemagic `picnic-app-patch-*` 워크플로 전용. 로컬 `shorebird patch` 는 금지 |
| 스테이징 빌드에 이 스킬 사용 | 스테이징은 `picnic-staging-v*` 태그라 범위 밖이다. 사용자에게 확인한다 |
| 직전 빌드가 실패했는데 `patch` 로 새 버전을 범프함 | 실패한 버전은 같은 버전의 빌드 순번만 올린다. 0의 `status` 로 확인하고 1의 표를 따른다 |
| main 의 태그되지 않은 버전을 다시 범프함 | 그 번호를 건너뛰게 된다. `next` 가 멈추면 범프 없이 7부터 한다 |
| "출시해줘" 를 submit 승인으로 봄 | check 결과와 출시 범위를 보여주고 따로 승인받는다 |
| 출시 노트 파일을 만들거나 노트용 PR 을 올림 | 노트는 직전 출시본에서 복사한다. 바꿀 때만 콘솔에서 직전 출시본의 노트를 고친다 |
| 스테이징 빌드 번호를 출시 대상으로 지정 | 같은 앱에 올라가지만 스테이징 환경 빌드다. 스크립트가 거부한다 — 프로덕션 태그 버전만 쓴다 |
