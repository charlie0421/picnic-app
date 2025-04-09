# 리소스 생성 가이드

이 문서는 Picnic Admin 프로젝트에서 새로운 리소스 컴포넌트를 생성하기 위한 가이드입니다.

## 목차

1. [개요](#개요)
2. [일반 리소스 생성](#일반-리소스-생성)
3. [DDL 기반 리소스 생성](#ddl-기반-리소스-생성)
4. [리소스 생성 후 작업](#리소스-생성-후-작업)
5. [추가 커스터마이징](#추가-커스터마이징)

## 개요

Picnic Admin 프로젝트에서는 두 가지 방법으로 새로운 리소스 컴포넌트를 생성할 수 있습니다:

1. 일반 요구사항 기반 리소스 생성 (`generate-resource`)
2. 데이터베이스 DDL 기반 리소스 생성 (`generate-resource-from-ddl`)

두 방법 모두 Cursor AI를 활용하여 빠르고 일관된 방식으로 리소스 컴포넌트를 생성합니다.

## 일반 리소스 생성

### 사용 방법

```bash
npm run generate-resource
```

이 명령어를 실행하면 다음과 같은 프롬프트 템플릿이 출력됩니다:

```
리소스 생성을 시작합니다.

Cursor AI에 다음 프롬프트를 입력하세요:

다음 요구사항에 맞는 Refine 리소스 CRUD 컴포넌트를 생성해주세요:

리소스 이름: [리소스명]
표시 이름: [표시명]
주요 필드:
- title (다국어)
- [추가 필드]

표준 코드 스타일을 적용하고, Refine 기본 컴포넌트를 최대한 활용해주세요.
```

### 사용 예시

아래와 같이 템플릿을 수정하여 Cursor AI에 입력합니다:

```
다음 요구사항에 맞는 Refine 리소스 CRUD 컴포넌트를 생성해주세요:

리소스 이름: article
표시 이름: 아티클
주요 필드:
- title (다국어)
- content (다국어)
- thumbnail
- is_published (boolean)
- category_id (관계: category)
- published_at (날짜)

표준 코드 스타일을 적용하고, Refine 기본 컴포넌트를 최대한 활용해주세요.
```

## DDL 기반 리소스 생성

### 사용 방법

```bash
npm run generate-resource-from-ddl
```

이 명령어를 실행하면 다음과 같은 프롬프트 템플릿이 출력됩니다:

```
DDL 기반 리소스 생성을 시작합니다.

Cursor AI에 다음 프롬프트를 입력하세요:

다음 DDL을 기반으로 Refine 리소스 CRUD 컴포넌트를 생성해주세요:

CREATE TABLE [테이블명] (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  [필드1] [타입] [제약조건],
  [필드2] [타입] [제약조건],
  ...
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

리소스 이름: [리소스명]
표시 이름: [표시명]
다국어 필드: [필드1, 필드2, ...] (해당되는 경우)

app/[리소스명] 폴더에 표준 CRUD 구조(리스트/생성/수정/상세)를 생성하고, Refine 기본 컴포넌트를 최대한 활용해주세요.
```

### 사용 예시

아래와 같이 템플릿을 수정하여 Cursor AI에 입력합니다:

```
다음 DDL을 기반으로 Refine 리소스 CRUD 컴포넌트를 생성해주세요:

CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title JSONB NOT NULL,
  content JSONB,
  thumbnail TEXT,
  is_published BOOLEAN DEFAULT false,
  category_id UUID REFERENCES categories(id),
  published_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

리소스 이름: article
표시 이름: 아티클
다국어 필드: title, content

app/article 폴더에 표준 CRUD 구조(리스트/생성/수정/상세)를 생성하고, Refine 기본 컴포넌트를 최대한 활용해주세요.
```

## 리소스 생성 후 작업

Cursor AI를 통해 리소스를 생성한 후에는 다음 작업을 진행해야 합니다:

1. 생성된 코드 검토 및 수정
   - 표준 코드 스타일 적용 여부 확인
   - 오류나 누락된 부분 확인

2. 데이터 모델 연결
   - 데이터 모델 타입 정의 추가 (`@/lib/types/[리소스명].ts`)
   - 필요한 경우 API 데이터 프로바이더 설정

3. 권한 설정
   - 권한 설정 추가 (`AuthorizePage` 컴포넌트 내의 resource 및 action 속성 확인)

4. 메뉴에 리소스 추가
   - `app/layout.tsx` 파일에서 사이드바 메뉴에 리소스 항목 추가

## 추가 커스터마이징

### 다국어 필드 처리

다국어 필드는 `MultiLanguageInput` 컴포넌트를 사용하여 처리합니다:

```tsx
<MultiLanguageInput name="title" label="제목" required={true} />
```

### 관계 필드 처리

관계 필드는 `Select` 컴포넌트와 `useMany` 훅을 사용하여 처리합니다:

```tsx
// 데이터 가져오기
const { data: categoriesData, isLoading: categoriesLoading } = useMany({
  resource: "categories",
  ids: [],
  queryOptions: {
    enabled: true,
  },
});

// 폼 필드
<Form.Item
  label="카테고리"
  name="category_id"
  rules={[{ required: true, message: "카테고리를 선택해주세요" }]}
>
  <Select
    loading={categoriesLoading}
    options={categoriesData?.data?.map((item) => ({
      label: item.name?.ko || item.name?.en || "N/A",
      value: item.id,
    }))}
    placeholder="카테고리 선택"
  />
</Form.Item>
```

### 파일 업로드 필드 처리

파일 업로드 필드는 `ImageUpload` 컴포넌트를 사용하여 처리합니다:

```tsx
<Form.Item
  label="썸네일"
  name="thumbnail"
  rules={[{ required: true, message: "썸네일을 업로드해주세요" }]}
>
  <ImageUpload />
</Form.Item>
```

### 날짜 필드 처리

날짜 필드는 `DatePicker` 컴포넌트와 `dayjs`를 사용하여 처리합니다:

```tsx
// 날짜 필드
<Form.Item
  label="발행일"
  name="published_at"
  getValueProps={(value) => ({
    value: value ? dayjs(value) : undefined,
  })}
>
  <DatePicker style={{ width: "100%" }} />
</Form.Item>

// 날짜 변환 로직
const handleSave = async (values: any) => {
  let updatedValues = { ...values };
  
  if (values.published_at) {
    const dateStr = typeof values.published_at === "string"
      ? values.published_at
      : values.published_at.format("YYYY-MM-DD");
    
    updatedValues.published_at = dateStr;
  }
  
  return updatedValues;
};
```

### 불리언 필드 처리

불리언 필드는 `Switch` 컴포넌트를 사용하여 처리합니다:

```tsx
<Form.Item
  label="발행 여부"
  name="is_published"
  valuePropName="checked"
>
  <Switch />
</Form.Item>
``` 