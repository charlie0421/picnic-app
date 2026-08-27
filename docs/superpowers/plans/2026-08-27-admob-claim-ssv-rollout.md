## 목표

AdMob 보상 광고가 표시된 뒤 서버가 발급한 클레임 토큰을 AdMob SSV `custom_data`로 전달하고, callback 검증을 통과한 보상만 코튼으로 정산되도록 앱·Supabase 계약을 연결한다.

## 제약

- 클라이언트가 직접 코튼을 지급하거나 SSV 검증을 우회하지 않는다.
- 사용자 ID·환경·placement는 서버가 인증 세션과 정책으로 결정한다.
- Pangle/Internal 적립 흐름과 기존 `PAGBiddingRequest` 의존성 수정은 회귀시키지 않는다.
- production 배포, Edge Function 배포, secret/AdMob Console SSV URL 변경은 코드 검증 후 별도 승인 게이트로 남긴다.

## 작업 순서

1. 현재 앱, Edge Function, SQL 함수와 정책의 실제 계약을 읽기 전용으로 대조한다.
2. AdMob claim API를 추가/정비하고 `ADMOB` 채널 및 만료·중복 방지를 명시한다.
3. Flutter `AdRewardRepository`와 `AdmobPlatform`이 광고 표시 전에 claim을 발급받고 opaque token을 `customData`로 전달하도록 연결한다. 실패 시 광고를 표시하지 않고 사용자에게 재시도 가능한 상태를 반환한다.
4. callback 정산의 ad unit/reward item 포맷, allowlist, 정책 모드, 환경 플래그를 production·sandbox별로 검증하고 필요한 migration/test fixture를 추가한다.
5. 단위·통합 테스트와 SQL 검증 쿼리로 SSV 성공, 잘못된/만료/재사용 토큰, Pangle/Internal 회귀를 확인한다.
6. 빌드·정적 분석·테스트를 실행하고, 외부 설정과 배포에 필요한 명령 및 승인 대상을 명확히 보고한다.

## 완료 기준

- AdMob 광고의 `customData`가 `platform=...` 같은 임의 문자열이 아니라 서버 발급 opaque v2 claim token이다.
- callback 로그에서 토큰 검증·정산 성공을 확인할 수 있고, 같은 토큰 재전송은 중복 지급되지 않는다.
- Android/iOS ad unit 포맷이 정책/allowlist와 일치한다.
- 기존 Pangle/Internal 테스트와 Flutter/Android 빌드가 통과한다.
- production 변경은 실행 전 사용자 승인 항목으로 분리된다.
