# CRUD 생성 스크립트

이 스크립트는 JSON 설정 파일을 기반으로 리소스의 CRUD 페이지들을 자동으로 생성합니다.

## 사용법

```bash
# 스크립트 실행
npx ts-node scripts/generate-crud.ts <config-file>

# 예시
npx ts-node scripts/generate-crud.ts scripts/examples/config.json
```

## 설정 파일 형식

```json
{
  "name": "resource_name",      // 리소스 이름 (소문자, 언더스코어)
  "label": "표시 이름",         // 메뉴에 표시될 이름
  "parent": "parent_menu",      // 상위 메뉴 (선택사항)
  "icon": "IconName",          // Ant Design 아이콘 이름
  "fields": [                  // 필드 정의
    {
      "name": "field_name",    // 필드 이름
      "label": "필드 라벨",     // 표시될 라벨
      "type": "string",        // 타입 (string, text, number, date, boolean)
      "required": true         // 필수 입력 여부 (선택사항)
    }
  ]
}
```

## 지원하는 필드 타입

- `string`: 일반 텍스트 입력
- `text`: 여러 줄 텍스트 입력
- `number`: 숫자 입력
- `date`: 날짜 선택
- `boolean`: 스위치 (true/false)

## 생성되는 파일

1. 타입 정의
   - `lib/types/{resource_name}.ts`

2. 컴포넌트
   - `app/{resource_name}/components/{ResourceName}Form.tsx`

3. 페이지
   - `app/{resource_name}/page.tsx` (목록)
   - `app/{resource_name}/create/page.tsx` (생성)
   - `app/{resource_name}/edit/[id]/page.tsx` (수정)
   - `app/{resource_name}/show/[id]/page.tsx` (상세)

## 추가 작업

스크립트 실행 후 다음 작업이 필요합니다:

1. `lib/resources.ts`에 생성된 리소스 설정 추가
2. 필요한 경우 생성된 컴포넌트 커스터마이징
3. 권한 설정 확인 