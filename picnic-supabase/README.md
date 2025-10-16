# picnic-supabase

Supabase Edge Functions와 공유 유틸을 분리 관리하는 레포입니다.

## 구조

```
picnic-supabase/
├─ supabase/
│  └─ functions/
│     └─ check-ads-count/
│        ├─ index.ts
│        └─ deno.json
└─ shared/
   ├─ response.ts
   ├─ cors.ts
   ├─ utils.ts
   └─ services/
      ├─ jwt/
      │  ├─ index.ts
      │  └─ djwt.ts
      └─ ad-count-check/
         ├─ index.ts
         └─ ad-count-check-service.ts
```

## 배포
- Supabase 대시보드 → Edge Functions → `check-ads-count`에 이 레포의 `supabase/functions/check-ads-count` 경로를 반영하세요.
- 또는 CI/CD에서 해당 디렉터리만 아티팩트로 업로드하도록 설정합니다.

## 환경 변수
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## 참고
- 기본 플랫폼 배열에 `internal` 포함.
- `AD_LIMITS`에 `internal` 기본 한도 포함.
