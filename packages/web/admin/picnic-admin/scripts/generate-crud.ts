#!/usr/bin/env ts-node

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

interface Field {
  name: string;
  label: string;
  type: 'string' | 'text' | 'number' | 'date' | 'boolean';
  required?: boolean;
}

interface ResourceConfig {
  name: string; // 리소스 이름 (예: config)
  label: string; // 표시 이름 (예: 설정)
  parent?: string; // 상위 메뉴 (예: admin)
  icon: string; // 아이콘 이름 (예: ToolOutlined)
  fields: Field[]; // 필드 정의
}

// 템플릿 파일 경로
const TEMPLATES = {
  form: `
'use client';

import { Form, Input, DatePicker, Switch } from 'antd';
import { useForm } from '@refinedev/antd';
import { {{ResourceName}} } from '@/lib/types/{{resourceName}}';

type {{ResourceName}}FormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<{{ResourceName}}>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<{{ResourceName}}>>['saveButtonProps'];
};

export default function {{ResourceName}}Form({
  mode,
  formProps,
  saveButtonProps,
}: {{ResourceName}}FormProps) {
  return (
    <Form {...formProps} layout="vertical">
      {{#fields}}
      <Form.Item
        label="{{label}}"
        name="{{name}}"
        rules={[{{#required}}{ required: true, message: '{{label}}을(를) 입력해주세요' }{{/required}}]}
      >
        {{#if (eq type "text")}}
        <Input.TextArea rows={4} />
        {{else if (eq type "date")}}
        <DatePicker />
        {{else if (eq type "boolean")}}
        <Switch />
        {{else}}
        <Input />
        {{/if}}
      </Form.Item>
      {{/fields}}
    </Form>
  );
}`,

  list: `
'use client';

import {
  List,
  useTable,
  DateField,
  ShowButton,
  EditButton,
  DeleteButton,
} from '@refinedev/antd';
import { Table, Space } from 'antd';
import { {{ResourceName}} } from '@/lib/types/{{resourceName}}';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function {{ResourceName}}List() {
  const { tableProps } = useTable<{{ResourceName}}>({
    resource: '{{resourceName}}',
    syncWithLocation: true,
    sorters: {
      initial: [
        {
          field: 'created_at',
          order: 'desc',
        },
      ],
    },
  });

  const columns = [
    {{#fields}}
    {
      title: '{{label}}',
      dataIndex: '{{name}}',
      key: '{{name}}',
      {{#if (eq type "date")}}
      render: (value: any) => <DateField value={value} />,
      {{/if}}
    },
    {{/fields}}
    {
      title: '작업',
      dataIndex: 'actions',
      render: (_: any, record: {{ResourceName}}) => (
        <Space>
          <ShowButton hideText size="small" recordItemId={record.id} />
          <EditButton hideText size="small" recordItemId={record.id} />
          <DeleteButton hideText size="small" recordItemId={record.id} />
        </Space>
      ),
    },
  ];

  return (
    <AuthorizePage resource="{{resourceName}}" action="list">
      <List
        createButtonProps={{
          children: '{{label}} 추가',
        }}
      >
        <Table {...tableProps} columns={columns} rowKey="id" />
      </List>
    </AuthorizePage>
  );
}`,

  create: `
'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import {{ResourceName}}Form from '@/app/{{resourceName}}/components/{{ResourceName}}Form';
import { {{ResourceName}} } from '@/lib/types/{{resourceName}}';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function {{ResourceName}}Create() {
  const { formProps, saveButtonProps } = useForm<{{ResourceName}}>({
    resource: '{{resourceName}}',
  });
  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource="{{resourceName}}" action="create">
      <Create saveButtonProps={saveButtonProps}>
        {contextHolder}
        <{{ResourceName}}Form
          mode="create"
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Create>
    </AuthorizePage>
  );
}`,

  edit: `
'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useParams } from 'next/navigation';
import {{ResourceName}}Form from '@/app/{{resourceName}}/components/{{ResourceName}}Form';
import { {{ResourceName}} } from '@/lib/types/{{resourceName}}';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function {{ResourceName}}Edit() {
  const params = useParams();
  const id = params.id as string;

  const { formProps, saveButtonProps } = useForm<{{ResourceName}}>({
    resource: '{{resourceName}}',
    id,
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
  });

  const [messageApi, contextHolder] = message.useMessage();

  return (
    <AuthorizePage resource="{{resourceName}}" action="edit">
      <Edit saveButtonProps={saveButtonProps}>
        {contextHolder}
        <{{ResourceName}}Form
          mode="edit"
          id={id}
          formProps={formProps}
          saveButtonProps={saveButtonProps}
        />
      </Edit>
    </AuthorizePage>
  );
}`,

  show: `
'use client';

import { useOne } from '@refinedev/core';
import { Show } from '@refinedev/antd';
import { Typography, Card } from 'antd';
import { useParams } from 'next/navigation';
import { {{ResourceName}} } from '@/lib/types/{{resourceName}}';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

const { Title, Text } = Typography;

export default function {{ResourceName}}Show() {
  const params = useParams();
  const id = params.id as string;

  const { data, isLoading } = useOne<{{ResourceName}}>({
    resource: '{{resourceName}}',
    id,
  });

  const record = data?.data;

  return (
    <AuthorizePage resource="{{resourceName}}" action="show">
      <Show isLoading={isLoading}>
        <Card>
          {{#fields}}
          <Title level={5}>{{label}}</Title>
          <Text>
            {{#if (eq type "date")}}
            {record?.{{name}} && new Date(record.{{name}}).toLocaleString()}
            {{else}}
            {record?.{{name}}}
            {{/if}}
          </Text>

          {{/fields}}
        </Card>
      </Show>
    </AuthorizePage>
  );
}`,

  types: `
export interface {{ResourceName}} {
  id?: string;
  {{#fields}}
  {{name}}: {{#if (eq type "boolean")}}boolean{{else if (eq type "number")}}number{{else}}string{{/if}};
  {{/fields}}
  created_at?: string;
  updated_at?: string;
}`,

  resource: `
  {
    name: '{{resourceName}}',
    list: '/{{resourceName}}',
    create: '/{{resourceName}}/create',
    edit: '/{{resourceName}}/edit/:id',
    show: '/{{resourceName}}/show/:id',
    meta: {
      canDelete: true,
      {{#if parent}}
      parent: '{{parent}}',
      {{/if}}
      label: '{{label}} 관리',
      icon: '{{icon}}',
      list: {
        label: '{{label}} 목록',
      },
      create: {
        label: '{{label}} 추가',
      },
      edit: {
        label: '{{label}} 수정',
      },
      show: {
        label: '{{label}} 상세',
      },
    },
  },`,
};

function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function generateFile(template: string, data: any, outputPath: string) {
  // Handlebars 템플릿 처리 로직
  const content = template
    .replace(/\{\{ResourceName\}\}/g, capitalize(data.name))
    .replace(/\{\{resourceName\}\}/g, data.name)
    .replace(/\{\{label\}\}/g, data.label);

  // 디렉토리 생성
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // 파일 작성
  fs.writeFileSync(outputPath, content);
  console.log(`Generated: ${outputPath}`);
}

function generateCRUD(config: ResourceConfig) {
  const basePath = path.join('app', config.name);

  // 타입 정의 생성
  generateFile(
    TEMPLATES.types,
    config,
    path.join('lib', 'types', `${config.name}.ts`),
  );

  // 컴포넌트 생성
  generateFile(
    TEMPLATES.form,
    config,
    path.join(basePath, 'components', `${capitalize(config.name)}Form.tsx`),
  );

  // 페이지 생성
  generateFile(TEMPLATES.list, config, path.join(basePath, 'page.tsx'));
  generateFile(
    TEMPLATES.create,
    config,
    path.join(basePath, 'create', 'page.tsx'),
  );
  generateFile(
    TEMPLATES.edit,
    config,
    path.join(basePath, 'edit', '[id]', 'page.tsx'),
  );
  generateFile(
    TEMPLATES.show,
    config,
    path.join(basePath, 'show', '[id]', 'page.tsx'),
  );

  // resources.ts에 리소스 추가 안내
  console.log('\nAdd the following to lib/resources.ts:');
  console.log(
    TEMPLATES.resource
      .replace(/\{\{ResourceName\}\}/g, capitalize(config.name))
      .replace(/\{\{resourceName\}\}/g, config.name)
      .replace(/\{\{label\}\}/g, config.label)
      .replace(/\{\{parent\}\}/g, config.parent || '')
      .replace(/\{\{icon\}\}/g, config.icon),
  );
}

// 사용 예시
if (require.main === module) {
  if (process.argv.length < 3) {
    console.log('Usage: generate-crud <config-file>');
    process.exit(1);
  }

  const configFile = process.argv[2];
  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
  generateCRUD(config);
}

export { generateCRUD, type ResourceConfig, type Field };
