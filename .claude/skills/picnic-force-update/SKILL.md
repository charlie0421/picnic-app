---
name: picnic-force-update
description: picnic_app 강제 업데이트(강업) 기준을 올릴 때 사용한다 — "강업 걸어줘", "현재 버전으로 강업", "1.3.x 미만 막아줘", "force_version 올려줘". 프로덕션 public.version 을 수정하므로 사용자 명시 승인이 필수다. 기준을 내리는 데는 쓰지 않는다. ttja_app 에는 쓰지 않는다.
argument-hint: "[M.m.P]  (생략 시 origin/main 의 현재 표시 버전)"
---

# picnic_app 강제 업데이트

프로덕션 `public.version` 행의 `ios`·`android` JSON 에서 `version`(최신)과 `force_version`(강업 기준)을
대상 표시 버전으로 올린다. 앱은 `force_version > 설치 버전` 이면 스토어 이동 화면만 보여준다(`ForceUpdateOverlay`).
**빌드 번호는 비교하지 않는다** — 강업 기준은 항상 `M.m.P` 다.

## 절차

0. **대상 버전** — 인자가 없으면 `git fetch origin main && git show origin/main:picnic_app/pubspec.yaml | grep ^version:` 의 표시 버전.
   인자가 있으면 그 값(`M.m.P`).
1. **출시 확인** — 대상 버전이 **App Store 와 Play Store 양쪽에, 전 지역에, 100% 로** 공개돼 있어야 한다.
   에이전트는 스토어를 직접 볼 수 없으므로 사용자에게 **플랫폼별로** 묻는다: "iOS 와 Android 둘 다 심사 통과·공개 완료인가요? 단계적 출시(phased/staged rollout) 중이 아닌가요?"
   "출시됐다" 한 마디는 한쪽만·단계적 출시일 수 있다. Codemagic finished·Shorebird active 는 출시가 아니다.
   출시 전이거나 한쪽만이면 강업하지 않는다 — 그 플랫폼 사용자 전원이 스토어에서 받을 수 없는 버전을 요구받는다.
2. **영향 확인** — `scripts/app_version_ops.sh force set <M.m.P>` (dry-run). 현재 기준, **막히게 될 7일 활성 기기 수**(플랫폼별), 실행할 SQL 을 출력한다.
   필요하면 `scripts/app_version_ops.sh adoption` 으로 분포 전체를 본다.
3. **사용자 승인** — 2의 출력(특히 막히는 기기 수)을 보여주고 명시 승인을 받는다. **"강업 해줘" 라는 최초 요청은 이 승인이 아니다** — 숫자를 본 뒤의 답이어야 한다.
4. **적용** — `scripts/app_version_ops.sh force set <M.m.P> --apply`. `--apply` 도 2와 같은 경로라 현재 기준·막히는 기기 수를 **다시 계산해 출력한 뒤** UPDATE 한다 — 승인 뒤 시간이 지났어도 별도 재확인 명령은 필요 없고, 출력된 숫자가 승인 때와 크게 다르면 멈추고 다시 묻는다.
   UPDATE 는 `WHERE 현재 force_version ≤ 대상` 조건이라 그 사이 다른 운영자가 더 높은 기준을 넣었으면 갱신 0행으로 실패한다. 응답이 502/504 로 끊기면 재실행하지 않고 재조회로 판정한다. 적용 후 양쪽 `force_version` 이 대상과 같은지 스크립트가 검증한다.
5. **보고** — 적용 전/후 값, 막히는 기기 수, 적용 시각(UTC). Jira 상태는 건드리지 않는다.

## 스크립트가 거부하는 것

- PROD 에 링크되지 않은 워크트리 (`supabase link --project-ref xtijtefcycoeqludlngc`)
- 빌드 번호가 붙은 버전 (`1.3.5+130504`)
- 현재 `force_version` 보다 낮은 대상 — 이미 막힌 사용자를 다시 여는 것이라 별도 결정이 필요하다. 내려야 하면 SQL 을 직접 쓰고 이유를 기록한다

## 하지 않는 것

- iOS 만 / Android 만 올리기 — 스크립트는 양쪽을 같이 올린다. 한쪽만 출시됐으면 **기다린다**
- `url` 변경 — 스토어 URL 은 그대로 둔다. 바꿔야 하면 어드민 `/version` 화면
- `apk` 컬럼 — 레거시(1.1.40), 앱이 읽지 않는다. 건드리지 않는다

## 흔한 실수

| 실수 | 바로잡기 |
|---|---|
| 태그 푸시·빌드 완료 직후 강업 | 심사 통과·출시 뒤에만. 1단계 |
| `1.3.5+130504` 로 지정 | 표시 버전 `1.3.5` 만. 스크립트가 거부한다 |
| `version`(최신) 만 올리고 `force_version` 은 둠 | 그건 "업데이트 권장" 이지 강업이 아니다. 스크립트는 둘 다 올린다 |
| 어드민 화면과 스크립트를 섞어 씀 | 같은 행이다. 어느 쪽이든 되지만 적용 뒤 `force show` 로 최종값을 확인한다 |
