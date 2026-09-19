---
name: releasing-picnic-app
description: Use when asked to release, ship, or upload a new picnic_app store binary (새 버전 릴리스·업로드, "1.3.x 릴리즈 해줘"), to rebuild the same version with only the build number raised (빌드넘버만 올려서 재빌드·재태그, 실패한 Codemagic 빌드 재시도), or to push a picnic-v* release tag. Not for Shorebird OTA patches or ttja_app.
---

# picnic_app 신규 바이너리 릴리스

최신 `origin/main` 에 버전 범프를 머지하고, 그 커밋에 `picnic-v<버전>` 태그를 푸시해
Codemagic iOS/Android 프로덕션 빌드를 시작한다. 기계적 단계는 `scripts/release_picnic.sh` 가 맡는다.

**선독 필수:** `~/.config/ai-agent-policies/flutter-release.md` (MmPPBB 규칙·승인 게이트의 원본).

## 모드

| 인자 | 뜻 | 다음 버전 |
|---|---|---|
| `build` | **빌드 번호만** 올린다 — 같은 표시 버전 재빌드, 실패한 빌드 재시도 | `next build` (1.3.5+130501 → 1.3.5+130502) |
| `patch` (기본) · `minor` · `major` | 새 표시 버전 | `next patch` 등 (BB 는 01 로 초기화) |
| `1.3.5+130501` 처럼 명시 | 사용자가 준 값을 그대로 쓴다 | `bump` 가 형식·증가 여부를 검증 |

사용자가 버전을 말했으면 `next` 결과와 달라도 사용자 값을 쓰고, `bump` 가 거부할 때만 되묻는다.
`build` 모드도 절차는 아래와 동일하다 — 범프 PR 을 생략하지 않는다(태그는 pubspec 과 일치해야 하고,
커밋 하나에는 릴리스 태그가 하나만 붙을 수 있다).

## 절차

0. **실을 내용 확인** — `git fetch origin main --tags && git log --oneline "$(git describe --tags --abbrev=0 --match 'picnic-v*' origin/main)"..origin/main`.
   직전 릴리스 태그 이후 커밋이 곧 이번 릴리스 내용이다. 사용자가 "머지했다"고 한 수정이 목록에 없으면 멈추고 PR 번호를 묻는다
1. **버전 결정** — `scripts/release_picnic.sh next <build|patch|minor|major>`
2. **브랜치** — `git switch -c chore/release-<M>-<m>-<P>[-build-<BB>] origin/main --no-track`
   (워크트리 안에서만. 메인 폴더에서는 워크트리를 먼저 만든다)
3. **범프** — `scripts/release_picnic.sh bump <버전>` → 변경은 `picnic_app/pubspec.yaml` 한 줄이어야 한다
4. **가드 테스트** — `cd picnic_app && flutter test`. 끝난 뒤 `git status --short` 로 `pubspec.lock` 이 안 바뀌었는지 본다
5. **커밋·PR** — `chore(release): bump picnic to <버전>`. PR 본문에 0의 목록(직전 릴리스 태그 이후 PR)을 적는다
6. **머지** — squash. 한 줄 범프라 교차 리뷰는 생략한다
7. **태그 dry-run** — `scripts/release_picnic.sh tag [--skip-tests]` 가 태그·버전·대상 커밋을 출력한다
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

## 빌드 실패 시

기존 태그를 삭제·이동·재푸시하지 않는다. 같은 커밋에 접미사만 바꾼 태그를 하나 더 붙이지도 않는다
(`resolve_release_tag.sh` 가 커밋당 태그 1개를 요구하고, 스토어는 빌드 번호 재사용을 거부한다).
원인을 main 에 고친 뒤 **`build` 모드로 처음부터** 다시 돈다.

## 흔한 실수

| 실수 | 바로잡기 |
|---|---|
| 로컬 `main` 을 체크아웃해 태그하려 함 | 워크트리에서는 불가능하고 불필요하다. 스크립트가 `origin/main` 커밋을 직접 태그한다 |
| 릴리스 브랜치 HEAD 에 태그 | squash 머지라 브랜치 커밋 ≠ main 커밋. 항상 `origin/main` |
| GitHub 체크에 Android 가 없어 실패로 판단 | 체크는 빌드가 시작돼야 생긴다. `status` (Codemagic API) 로 `queued` 를 확인 |
| 이 절차로 OTA 를 내보냄 | OTA 는 태그 없이 Codemagic `picnic-app-patch-*` 워크플로 전용. 로컬 `shorebird patch` 는 금지 |
| 스테이징 빌드에 이 스킬 사용 | 스테이징은 `picnic-staging-v*` 태그라 범위 밖이다. 사용자에게 확인한다 |
