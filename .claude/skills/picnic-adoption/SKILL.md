---
name: picnic-adoption
description: picnic_app 버전 배포율(채택률)을 확인할 때 사용한다 — "배포율 확인", "몇 %가 새 버전이야", "1.3.x 사용자 얼마나 돼", "구버전 사용자 얼마나 남았어", 강업 전 영향 범위 확인. 프로덕션 Supabase 의 devices 테이블을 읽기만 한다. ttja_app 에는 쓰지 않는다.
argument-hint: "[--days N]"
---

# picnic_app 버전 배포율

프로덕션 `public.devices` 의 `app_version`·`app_build_number`·`last_seen` 으로 활성 기기의 버전 분포를 낸다.
읽기 전용이다.

## 실행

```bash
scripts/app_version_ops.sh adoption            # 최근 7일
scripts/app_version_ops.sh adoption --days 30
```

출력 세 표: ① 표시 버전별 기기 수·비율·iOS/Android ② 플랫폼 × 빌드 번호 상위 15 ③ 현재 강업 기준(`public.version`).

## 사전 조건

- 워크트리가 PROD 에 링크돼 있어야 한다: `supabase link --project-ref xtijtefcycoeqludlngc` (`supabase/.temp` 는 gitignore).
  스크립트가 링크를 확인하고 아니면 거부한다.
- Management API 가 502/504 를 자주 낸다. 스크립트가 4회까지 재시도한다. 그래도 실패하면 잠시 뒤 다시 돌린다 — 다른 경로(MCP `execute_sql`)도 같은 API 라 같이 죽는다.

## 보고할 때

- "현재 버전" 은 `origin/main` 의 `picnic_app/pubspec.yaml` 표시 버전이다. 그 행의 `pct` 가 배포율이다.
- 빌드 번호별 표에서 같은 표시 버전의 이전 빌드(예: 130502)가 남아 있으면 TestFlight·내부 테스트 기기다.
- 강업 기준(`force_version`) 미만 버전에 활성 기기가 있으면 그 수를 따로 말한다 — 그 사용자는 앱을 열어도 강업 화면에서 막힌다.

## 해석 주의

| 함정 | 사실 |
|---|---|
| `last_seen` = 앱을 실제로 쓴 시각 | 세션 복구·토큰 갱신 때 갱신된다(#242). 강업 화면에 막힌 기기도 갱신될 수 있으므로 "구버전 활성" ≠ "구버전으로 정상 사용 중" |
| `total` 을 분모로 쓴다 | 전체 34,000여 행 대부분은 오래 안 열린 기기다. 분모는 활성 기간 창으로 잡는다 |
| 사용자 수 = 기기 수 | 표는 기기 기준이다. 사용자 수가 필요하면 `count(distinct user_id)` 로 다시 센다 |
| `app_version` 이 null 인 행이 많다 | 7일 활성에서는 0 이다. 있으면 등록 경로 결함이니 보고한다 |
| `(invalid: …)` 행이 보인다 | `M.m.P` 형식이 아닌 값(`1.3.5-beta`, 빈 문자열 등)이다. 비교에서 제외되며, 강업 dry-run 의 "막히는 기기" 에도 안 잡힌다. 수가 크면 보고한다 |
