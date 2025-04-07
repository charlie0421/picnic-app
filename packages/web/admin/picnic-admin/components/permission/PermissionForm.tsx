'use client';

import { Form, Input, Select } from 'antd';
import { useForm } from '@refinedev/antd';
import { AdminPermission } from '@/types/permission';

// 액션 타입 옵션
const ACTION_OPTIONS = [
  { label: '조회', value: 'read' },
  { label: '생성', value: 'create' },
  { label: '수정', value: 'update' },
  { label: '삭제', value: 'delete' },
  { label: '모든 권한', value: '*' },
];

// 리소스 옵션
const RESOURCE_OPTIONS = [
  { label: '아티스트', value: 'artists' },
  { label: '미디어', value: 'media' },
  { label: '투표', value: 'votes' },
  { label: '권한', value: 'permissions' },
  { label: '역할', value: 'roles' },
  { label: '사용자', value: 'users' },
];

type PermissionFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<AdminPermission>>['formProps'];
  saveButtonProps: ReturnType<
    typeof useForm<AdminPermission>
  >['saveButtonProps'];
  onFinish?: (values: AdminPermission) => Promise<any>;
  redirectPath?: string;
};

export default function PermissionForm({
  mode,
  formProps,
  saveButtonProps,
}: PermissionFormProps) {
  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={formProps.initialValues || {}}
    >
      <Form.Item
        label='리소스'
        name='resource'
        rules={[
          {
            required: true,
            message: '리소스를 선택해 주세요',
          },
        ]}
      >
        <Select
          placeholder='리소스를 선택하세요'
          options={RESOURCE_OPTIONS}
          showSearch
          allowClear
        />
      </Form.Item>

      <Form.Item
        label='액션'
        name='action'
        rules={[
          {
            required: true,
            message: '액션을 선택해 주세요',
          },
        ]}
      >
        <Select
          placeholder='액션을 선택하세요'
          options={ACTION_OPTIONS}
          showSearch
          allowClear
        />
      </Form.Item>

      <Form.Item
        label='설명'
        name='description'
        rules={[
          {
            required: true,
            message: '권한에 대한 설명을 입력해 주세요',
          },
        ]}
      >
        <Input.TextArea placeholder='권한에 대한 설명을 입력하세요' rows={4} />
      </Form.Item>
    </Form>
  );
}
