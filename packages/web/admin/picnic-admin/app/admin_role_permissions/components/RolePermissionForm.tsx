'use client';

import { useEffect, useState } from 'react';
import { Form, Select, Table, Button, Space, Tag } from 'antd';
import { useForm, useSelect } from '@refinedev/antd';
import {
  AdminRolePermission,
  AdminRole,
  AdminPermission,
} from '@/lib/types/permission';

type RolePermissionFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<AdminRolePermission>>['formProps'];
  saveButtonProps: ReturnType<
    typeof useForm<AdminRolePermission>
  >['saveButtonProps'];
  onFinish?: (values: AdminRolePermission) => Promise<any>;
  redirectPath?: string;
};

export default function RolePermissionForm({
  mode,
  formProps,
  saveButtonProps,
}: RolePermissionFormProps) {
  const [selectedPermission, setSelectedPermission] = useState<string | null>(null);

  // 역할 목록 가져오기
  const { selectProps: roleSelectProps } = useSelect<AdminRole>({
    resource: 'admin_roles',
    optionLabel: 'name',
    optionValue: 'id',
  });

  // 권한 목록 가져오기
  const { selectProps: permissionSelectProps } = useSelect<AdminPermission>({
    resource: 'admin_permissions',
    optionLabel: (record) => `${record.resource} - ${record.action}`,
    optionValue: 'id',
  });

  // 초기 데이터 로드
  useEffect(() => {
    if (mode === 'edit' && formProps.initialValues) {
      const { role_id, permission_id } = formProps.initialValues;
      formProps.form?.setFieldsValue({ role_id, permission_id });
      setSelectedPermission(permission_id);
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
        label='권한'
        name='permission_id'
        rules={[
          {
            required: true,
            message: '권한을 선택해 주세요',
          },
        ]}
      >
        <Select
          placeholder='권한을 선택하세요'
          {...permissionSelectProps}
          showSearch
          allowClear
          onChange={(value) => {
            setSelectedPermission(value ? value.toString() : null);
          }}
        />
      </Form.Item>
    </Form>
  );
}
