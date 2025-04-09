# 리소스 컴포넌트 표준화 가이드

이 문서는 Picnic Admin 프로젝트의 리소스 컴포넌트를 표준화된 코드 스타일로 변환하기 위한 가이드입니다.

## 목차

1. [개요](#개요)
2. [표준화 규칙](#표준화-규칙)
3. [표준화 도구](#표준화-도구)
4. [표준화 프로세스](#표준화-프로세스)
5. [체크리스트](#체크리스트)
6. [템플릿 예시](#템플릿-예시)

## 개요

Picnic Admin 프로젝트는 Next.js App Router와 Refine 프레임워크를 기반으로 구축되었으며, 
여러 리소스에 대한 CRUD 컴포넌트로 구성되어 있습니다. 
이 가이드는 모든 리소스 컴포넌트에 일관된 코드 스타일을 적용하여 가독성과 유지보수성을 향상시키는 것을 목표로 합니다.

## 표준화 규칙

모든 리소스 컴포넌트는 다음 규칙을 준수해야 합니다:

### 1. 모든 페이지 공통 사항

- `AuthorizePage` 컴포넌트로 감싸기
- 리소스 이름 명시적 지정 (useTable, useForm, useShow 등의 hook에서)
- `useResource` 훅 활용 및 title 속성에 적용
- 불필요한 import 제거 및 import 정리
- 가독성을 위한 적절한 공백 추가
- 모든 문자열은 큰따옴표(`"`)로 통일
- UI 컴포넌트는 `@/components/ui` 경로에서 가져오기

### 2. 페이지별 특이사항

#### 리스트 페이지 (`page.tsx`)
- `useTable` 사용 시 resource 명시
- 검색 및 필터링 로직 표준화
- TableColumn 간 일관된 스타일 적용

#### 생성 페이지 (`create/page.tsx`)
- `useForm` 사용 시 resource 명시
- 표준화된 메시지 처리

#### 수정 페이지 (`edit/[id]/page.tsx`)
- `useForm` 사용 시 resource 및 id 명시
- 값 변환 로직 표준화 (예: 날짜 처리)

#### 상세 페이지 (`show/[id]/page.tsx`)
- `useShow` 사용 시 resource 명시
- 일관된 UI 레이아웃 적용

## 표준화 도구

프로젝트에는 리소스 컴포넌트 표준화를 위한 도구가 포함되어 있습니다:

```bash
npm run standardize-resources
```

이 명령어는 다음 작업을 수행합니다:
1. 모든 리소스 디렉토리 탐색
2. 각 리소스의 CRUD 페이지 파일 식별
3. 표준화가 필요한 파일 목록 출력
4. 파일별 표준화 가이드 출력

## 표준화 프로세스

### 1. 표준화 대상 파일 식별

```bash
npm run standardize-resources
```

이 명령어를 실행하면 표준화가 필요한 모든 파일 목록이 출력됩니다.

### 2. 표준화 적용

각 파일에 대해 Cursor AI를 사용하여 표준화를 적용합니다:

1. 파일을 엽니다
2. 다음 프롬프트를 Cursor AI에 입력합니다:

```
이 파일을 표준 코드 스타일로 리팩토링해주세요:
1. AuthorizePage 컴포넌트로 감싸기
2. resource 이름 명시 (useTable, useForm, useShow 등에서)
3. useResource 훅 사용 및 title 적용
4. 불필요한 import 제거 및 import 정리
5. 가독성을 위한 적절한 공백 추가
6. 모든 문자열은 큰따옴표로 통일
7. UI 컴포넌트 import 방식 통일 (@/components/ui에서 가져오기)
```

3. 표준화된 코드를 검토 및 테스트합니다
4. 다음 파일로 이동합니다

### 3. 표준화 확인

모든 파일에 표준화를 적용한 후, 다음을 확인합니다:
- 모든 페이지가 정상적으로 동작하는지 확인
- 코드 스타일이 일관되게 적용되었는지 확인

## 체크리스트

각 파일을 표준화한 후 다음 체크리스트를 확인하세요:

- [ ] 모든 페이지가 AuthorizePage로 감싸져 있는지 확인
- [ ] Resource 이름이 모든 관련 훅에 명시되어 있는지 확인
- [ ] useResource 훅을 사용하고 title 속성에 적용되어 있는지 확인
- [ ] 불필요한 import가 제거되었는지 확인
- [ ] 코드 포맷팅이 통일되었는지 확인
- [ ] UI 컴포넌트 import 방식이 통일되었는지 확인

## 템플릿 예시

### 리스트 페이지 템플릿 (`page.tsx`)

```tsx
'use client';

import { CreateButton, DateField, List, useTable } from "@refinedev/antd";
import { Table, Input, Space } from "antd";
import { useNavigation, useResource } from "@refinedev/core";
import { useState } from "react";
import { AuthorizePage } from "@/components/auth/AuthorizePage";

export default function ResourceList() {
  const [searchTerm, setSearchTerm] = useState<string>("");
  const { show } = useNavigation();
  const { resource } = useResource();

  const { tableProps } = useTable({
    resource: "resource_name", // 리소스명 명시
    syncWithLocation: true,
    sorters: {
      initial: [{ field: "id", order: "desc" }],
    },
    meta: {
      search: searchTerm
        ? { query: searchTerm, fields: ["field.ko", "field.en"] }
        : undefined,
    },
  });

  // 검색 핸들러
  const handleSearch = (value: string) => {
    setSearchTerm(value);
  };

  return (
    <AuthorizePage resource="resource_name" action="list">
      <List 
        breadcrumb={false}
        headerButtons={<CreateButton />}
        title={resource?.meta?.list?.label}
      >
        {/* 리스트 컴포넌트 내용 */}
      </List>
    </AuthorizePage>
  );
}
```

### 생성 페이지 템플릿 (`create/page.tsx`)

```tsx
'use client';

import { Create, useForm } from "@refinedev/antd";
import { Form, message } from "antd";
import { useResource } from "@refinedev/core";
import { AuthorizePage } from "@/components/auth/AuthorizePage";

export default function ResourceCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm({
    resource: "resource_name", // 리소스명 명시
    warnWhenUnsavedChanges: true,
    redirect: "list",
    onMutationSuccess: () => {
      messageApi.success("리소스가 성공적으로 생성되었습니다");
    },
  });

  return (
    <AuthorizePage resource="resource_name" action="create">
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <Form {...formProps} layout="vertical">
          {/* 폼 컴포넌트 내용 */}
        </Form>
      </Create>
    </AuthorizePage>
  );
}
```

### 수정 페이지 템플릿 (`edit/[id]/page.tsx`)

```tsx
'use client';

import { Edit, useForm } from "@refinedev/antd";
import { Form, message } from "antd";
import { useParams } from "next/navigation";
import { useResource } from "@refinedev/core";
import { AuthorizePage } from "@/components/auth/AuthorizePage";

export default function ResourceEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const { formProps, saveButtonProps } = useForm({
    resource: "resource_name", // 리소스명 명시
    id,
    warnWhenUnsavedChanges: true,
    redirect: "list",
    onMutationSuccess: () => {
      messageApi.success("리소스가 성공적으로 수정되었습니다");
    },
  });

  return (
    <AuthorizePage resource="resource_name" action="edit">
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <Form {...formProps} layout="vertical">
          {/* 폼 컴포넌트 내용 */}
        </Form>
      </Edit>
    </AuthorizePage>
  );
}
```

### 상세 페이지 템플릿 (`show/[id]/page.tsx`)

```tsx
'use client';

import { useShow, useResource } from "@refinedev/core";
import { Show, DateField } from "@refinedev/antd";
import { theme, Typography } from "antd";
import { AuthorizePage } from "@/components/auth/AuthorizePage";

const { Title } = Typography;

export default function ResourceShow() {
  const { queryResult } = useShow({ resource: "resource_name" }); // 리소스명 명시
  const { data, isLoading } = queryResult;
  const record = data?.data;
  const { resource } = useResource();
  
  const { token } = theme.useToken();

  return (
    <AuthorizePage resource="resource_name" action="show">
      <Show
        breadcrumb={false}
        title={resource?.meta?.show?.label}
        isLoading={isLoading}
      >
        {/* 상세 정보 컴포넌트 내용 */}
      </Show>
    </AuthorizePage>
  );
}
``` 