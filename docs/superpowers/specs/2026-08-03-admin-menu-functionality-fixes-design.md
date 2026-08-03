# 관리자 메뉴 기능 보완 설계

## 목표

관리자 메뉴의 캔디 내역, 충전 내역, GDPR 초기화 기능을 실제 운영 계약에 맞게 동작시키고 기존 MyPage와 동일한 좌우 여백을 적용한다.

## 확인된 원인

- 운영 `get_currency_history` RPC는 `wallet.cotton_read_enabled`가 꺼져 있을 때 `COTTON_CANDY` 요청에 `WALLET_COTTON_READ_DISABLED`를 반환한다. 현재 운영 플래그는 `false`다.
- `충전 내역`의 `onTap`은 관리자 메뉴 이동 전부터 빈 함수였고 연결된 화면이 없다.
- 운영 DB에는 super admin 전용 `get_payment_breakdown(p_start, p_end, p_dimension)` RPC가 있으며 `platform`과 `product` 집계를 반환한다.
- GDPR 콜백은 reset 전에 상태 조회를 기다린다. 상태 조회가 실패하면 reset에 도달하지 못하고, 성공해도 이름과 달리 앱을 reload하지 않는다.
- 새 `AdminMenuPage`의 목록은 기존 MyPage에 있던 `EdgeInsets.symmetric(horizontal: 16)` 컨테이너를 사용하지 않는다.

## 화면과 데이터 흐름

### 관리자 메뉴

- 기존 네 항목을 유지한다.
- 전체 목록을 좌우 16px 패딩으로 감싼다.
- `캔디 내역`은 기존 `CurrencyHistoryPage`로 이동한다.
- `충전 내역`은 새 `ChargeHistoryPage`로 이동한다.

### 캔디 내역

- 운영에서 읽기가 비활성화된 코튼캔디 탭을 제거한다.
- 스타캔디와 보너스 스타캔디 두 탭만 제공한다.
- 기존 관리자 권한 검사, 페이징, 오류 표시를 유지한다.
- 콘텐츠에 좌우 16px 패딩을 적용한다.

### 충전 내역

- 관리자 전용 `ChargeHistoryPage`를 추가한다.
- 페이지 자체에서 `userInfoProvider`의 `isAdmin`을 재검사한다.
- 관리자에게 `플랫폼별`과 `상품별` 두 탭을 제공한다.
- 각 탭은 `get_payment_breakdown`을 각각 `platform`, `product` 차원으로 호출한다.
- 행에는 집계 키, 결제 건수, USD 매출을 표시한다.
- 로딩, 빈 결과, RPC 오류 상태를 화면에 표시한다.
- 일반 사용자나 로그아웃 사용자의 직접 접근은 `접근 권한이 없습니다.`로 차단한다.
- 콘텐츠에 좌우 16px 패딩을 적용한다.

### GDPR 초기화

- reset 전에 실행하던 상태 조회는 제거한다.
- `ConsentService.resetAndReinitialize()`를 직접 호출하고 모든 예외를 실패 결과로 처리한다.
- 실행 중에는 중복 탭을 막고 진행 안내를 표시한다.
- 성공하면 성공 안내 후 `Phoenix.rebirth(context)`로 앱을 실제 reload한다.
- 실패하면 앱을 reload하지 않고 실패 안내를 표시한다.
- 완료 후 상태 로깅은 best-effort로 수행하며 실패해도 reset 결과를 바꾸지 않는다.
- 테스트에서 플랫폼 채널 없이 성공·실패·예외·중복 실행을 검증할 수 있도록 동작 의존성을 주입 가능한 작은 컨트롤러/콜백 경계로 분리한다.

## Supabase 변경 범위

- 운영 스키마나 Edge Function은 변경하지 않는다.
- 기존 `get_payment_breakdown` RPC만 읽기 호출한다.
- 앱의 `isAdmin` 화면 가드와 DB의 `is_super_admin()` 검사를 함께 유지한다. 앱 관리자이지만 super admin이 아닌 계정은 RPC 오류 상태를 보게 되며 데이터가 노출되지 않는다.

## 테스트

- 캔디 내역에 스타캔디와 보너스 스타캔디만 표시되고 코튼캔디 요청이 발생하지 않는지 검증한다.
- 관리자 메뉴 및 두 하위 화면의 좌우 16px 패딩을 검증한다.
- 충전 내역의 플랫폼별/상품별 RPC 파라미터와 렌더링, 로딩, 오류, 권한 차단을 검증한다.
- 관리자 메뉴에서 충전 내역을 탭하면 새 화면으로 이동하는지 검증한다.
- GDPR 성공 시 reload, 실패·예외 시 오류 안내와 reload 미실행, 실행 중 중복 탭 방지를 검증한다.
- 관련 위젯 테스트와 정적 분석을 통과한 커밋만 OTA에 사용한다.

## 배포

- 기존 PR 브랜치에 커밋하고 푸시한다.
- `picnic_app/pubspec.yaml`의 `1.3.0+130001`을 확인한다.
- 태그와 Codemagic 없이 로컬 Shorebird로 iOS와 Android stable 패치를 생성한다.
- 게시 후 패치 번호, 플랫폼, stable 채널, rollback 여부를 다시 조회한다.
