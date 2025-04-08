'use client';

import { useEffect, useState } from 'react';
import { Form, Select, Input } from 'antd';
import { useForm, useSelect } from '@refinedev/antd';
import { AdminUserRole, AdminRole } from '@/lib/types/permission';

type RoleUserFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<AdminUserRole>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<AdminUserRole>>['saveButtonProps'];
  onFinish?: (values: AdminUserRole) => Promise<any>;
  redirectPath?: string;
};

export default function RoleUserForm({
  mode,
  formProps,
  saveButtonProps,
}: RoleUserFormProps) {
  const [selectedUser, setSelectedUser] = useState<string | null>(null);

  // 역할 목록 가져오기
  const { selectProps: roleSelectProps } = useSelect<AdminRole>({
    resource: 'admin_roles',
    optionLabel: 'name',
    optionValue: 'id',
  });

  // 사용자 목록 가져오기 (useSelect 사용)
  const { selectProps: userSelectProps, queryResult } = useSelect<any>({
    resource: 'user_profiles',
    optionLabel: (item) => item.email || `ID: ${item.id}`,
    optionValue: (item) => item.id,
    onSearch: (value) => [
      {
        field: 'email',
        operator: 'containss',
        value: value,
      },
    ],
    queryOptions: {
      enabled: mode === 'create' || !!formProps.initialValues?.user_id,
    },
    filters:
      mode === 'edit' && formProps.initialValues?.user_id
        ? [
            {
              field: 'id',
              operator: 'eq',
              value: formProps.initialValues.user_id,
            },
          ]
        : [],
  });

  // 초기 데이터 로드 (useEffect는 form 값 설정만 담당)
  useEffect(() => {
    if (mode === 'edit' && formProps.initialValues) {
      const { role_id, user_id } = formProps.initialValues;
      formProps.form?.setFieldsValue({ role_id, user_id });
      setSelectedUser(user_id);
    }
  }, [mode, formProps.initialValues, formProps.form]);

  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={formProps.initialValues || {}}
    >
      <Form.Item
        label='역할'
        name='role_id'
        rules={[
          {
            required: true,
            message: '역할을 선택해 주세요',
          },
        ]}
      >
        <Select
          placeholder='역할을 선택하세요'
          {...roleSelectProps}
          showSearch
          allowClear
        />
      </Form.Item>

      <Form.Item
        label='사용자'
        name='user_id'
        rules={[
          {
            required: true,
            message: '사용자를 선택해 주세요',
          },
        ]}
      >
        <Select
          placeholder='사용자 이메일을 검색하세요'
          {...userSelectProps}
          showSearch
          allowClear
          filterOption={false}
          loading={queryResult.isLoading}
          onChange={(value) => {
            setSelectedUser(String(value));
          }}
        />
      </Form.Item>

      {selectedUser && (
        <Form.Item label='선택된 사용자 ID'>
          <Input value={selectedUser} disabled />
        </Form.Item>
      )}
    </Form>
  );
}
