# 관리자 활동 로깅 시스템

이 문서는 피크닠 관리자 시스템의 활동 로깅 시스템에 대한 설명입니다.

## 개요

관리자 활동 로깅 시스템은 다음과 같은 목적으로 구현되었습니다:

- 관리자 계정의 활동 감사(Audit)
- 시스템 변경 이력 추적
- 보안 사고 발생 시 추적 및 조사 용이
- 사용자 행동 패턴 분석

## 데이터베이스 구조

활동 로그는 `activities` 테이블에 저장되며, 구조는 다음과 같습니다:

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | BIGSERIAL | 고유 식별자 (PK) |
| user_id | UUID | 활동을 수행한 관리자 ID (FK to auth.users) |
| activity_type | TEXT | 활동 유형 (CREATE, READ, UPDATE, DELETE 등) |
| resource_type | TEXT | 리소스 유형 (USER, VOTE, BANNER 등) |
| resource_id | TEXT | 리소스 ID |
| description | TEXT | 활동 설명 |
| details | JSONB | 활동 세부 정보 (JSON 형식) |
| ip_address | TEXT | IP 주소 |
| user_agent | TEXT | 사용자 에이전트 |
| timestamp | TIMESTAMPTZ | 활동 발생 시간 |

### 인덱스

성능 최적화를 위해 다음과 같은 인덱스가 생성되어 있습니다:

- `activities_activity_type_idx`: 활동 유형별 조회 최적화
- `activities_resource_type_idx`: 리소스 유형별 조회 최적화
- `activities_timestamp_idx`: 시간 기준 내림차순 정렬 최적화
- `activities_user_id_timestamp_idx`: 사용자별 활동 조회 최적화

## 접근 제어

Row Level Security(RLS)를 통해 다음과 같은 접근 제어가 구현되어 있습니다:

- 관리자 계정만 활동 로그를 읽을 수 있음
- 관리자 계정만 활동 로그를 작성할 수 있음
- 일반 사용자는 활동 로그에 접근할 수 없음

## 활동 유형

시스템은 다음과 같은 활동 유형을 기록합니다:

- `CREATE`: 리소스 생성
- `READ`: 리소스 조회
- `UPDATE`: 리소스 수정
- `DELETE`: 리소스 삭제
- `LOGIN`: 로그인
- `LOGOUT`: 로그아웃
- `EXPORT`: 데이터 내보내기
- `IMPORT`: 데이터 가져오기
- `APPROVE`: 승인
- `REJECT`: 거부
- `OTHER`: 기타 활동

## 리소스 유형

시스템에서 관리하는 주요 리소스 유형은 다음과 같습니다:

- `USER`: 사용자 관련
- `VOTE`: 투표 관련
- `BANNER`: 배너 관련
- `MEDIA`: 미디어 관련
- `SYSTEM`: 시스템 관련
- `SETTING`: 설정 관련

## 사용 방법

### 기본 로깅 함수

활동 로깅을 위한 기본 함수는 다음과 같습니다:

```typescript
import { logActivity, ActivityType, ResourceType } from '@/lib/services/activityLogger';

// 기본 로깅 함수
await logActivity(
  ActivityType.CREATE,  // 활동 유형
  ResourceType.USER,    // 리소스 유형
  '사용자 생성',        // 활동 설명
  '123',                // 리소스 ID (선택사항)
  { name: '홍길동' }    // 세부 정보 (선택사항)
);
```

### 훅 사용하기

React 컴포넌트에서 활동 로깅을 더 쉽게 하기 위한 훅을 제공합니다:

```typescript
import { useActivityLogger } from '@/lib/hooks/useActivityLogger';

function AdminComponent() {
  const { logCreate, logUpdate, logDelete } = useActivityLogger();
  
  const handleCreateUser = async (userData) => {
    // 사용자 생성 로직...
    await logCreate(ResourceType.USER, '사용자 생성', userId, userData);
  };
  
  // ...
}
```

## 활동 로그 조회

관리자는 `/activities` 페이지에서 모든 활동 로그를 조회할 수 있습니다. 다음과 같은 필터링 옵션을 제공합니다:

- 날짜 범위
- 활동 유형
- 리소스 유형
- 사용자
- 키워드 검색

## 로그 보존 정책

기본적으로 활동 로그는 180일 동안 보존됩니다. 이후에는 자동으로 삭제됩니다.

## 모범 사례

### 로깅 시점

다음과 같은 경우에 활동 로깅을 수행하는 것이 좋습니다:

1. 관리자가 로그인/로그아웃할 때
2. 중요 페이지 접근 시 (대시보드, 설정 등)
3. 데이터 생성/수정/삭제 시
4. 민감한 데이터 조회 시
5. 시스템 설정 변경 시
6. 배치 작업 수행 시

### 로깅 세부 정보

로깅 시 다음과 같은 정보를 포함하는 것이 좋습니다:

- 활동 전/후 상태 (수정의 경우)
- 영향을 받은 레코드 수 (배치 작업의 경우)
- 작업의 성공/실패 여부
- 실패한 경우 오류 정보

## 보안 고려사항

1. 민감한 개인 정보는 로그에 포함하지 않아야 합니다.
2. 패스워드 등의 보안 정보는 절대로 로그에 기록하지 않아야 합니다.
3. 로그 데이터에 대한 접근 제어가 적절히 구현되어야 합니다.

## 로그 분석

향후 다음과 같은 로그 분석 기능이 구현될 예정입니다:

- 관리자별 활동 통계
- 시간대별 활동 패턴 분석
- 이상 징후 탐지
- 정기 활동 보고서 생성 