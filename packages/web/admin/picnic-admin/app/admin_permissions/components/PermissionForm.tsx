'use client';

import { Form, Input, Select, message } from 'antd';
import { useForm } from '@refinedev/antd';
import { useList } from '@refinedev/core';
import { AdminPermission } from '@/lib/types/permission';

// 액션 타입 옵션
const ACTION_OPTIONS = [
  { label: '조회', value: 'read' },
  { label: '생성', value: 'create' },
  { label: '수정', value: 'update' },
  { label: '삭제', value: 'delete' },
  { label: '모든 권한', value: '*' },
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
  // 기존 권한 목록 조회
  const { data: existingPermissions } = useList<AdminPermission>({
    resource: 'admin_permissions',
  });

  // Form 제출 전 중복 체크
  const handleFinish = async (values: any) => {
    // 현재 수정 중인 권한 ID (수정 모드일 경우)
    const currentId = formProps.initialValues?.id;

    // 동일한 리소스-액션 조합이 있는지 확인
    const isDuplicate = existingPermissions?.data?.some(
      (permission) =>
        permission.resource === values.resource &&
        permission.action === values.action &&
        permission.id !== currentId // 수정 시 자기 자신은 제외
    );

    if (isDuplicate) {
      message.error('이미 존재하는 리소스-액션 조합입니다.');
      return false;
    }

    return formProps.onFinish?.(values);
  };

  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={formProps.initialValues || {}}
      onFinish={handleFinish}
    >
      <Form.Item
        label='리소스'
        name='resource'
        rules={[
          {
            required: true,
            message: '리소스를 입력해 주세요',
          },
        ]}
      >
        <Input placeholder='리소스를 입력하세요' />
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
