'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, InputNumber, Switch, Select, DatePicker, message } from 'antd';
import { genderOptions } from '../../../lib/types/user_profiles';
import { useResource } from '@refinedev/core';
import dayjs from 'dayjs';

interface UserProfileEditProps {
  id: string;
  resource?: string;
}

export function UserProfileEdit({ id, resource = 'user_profiles' }: UserProfileEditProps) {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource: resourceInfo } = useResource();

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource,
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('사용자 정보가 성공적으로 수정되었습니다');
    },
  });

  // 데이터 로딩 중인 경우 처리
  const isLoading = queryResult?.isLoading;
  const record = queryResult?.data?.data;

  // 날짜 데이터 변환
  const transformedFormProps = {
    ...formProps,
    initialValues: {
      ...formProps.initialValues,
      birth_date: formProps.initialValues?.birth_date
        ? dayjs(formProps.initialValues.birth_date)
        : undefined,
    },
  };

  return (
    <Edit
      breadcrumb={false}
      title="사용자 정보 수정"
      saveButtonProps={saveButtonProps}
      isLoading={isLoading}
    >
      {contextHolder}
      <Form {...transformedFormProps} layout="vertical">
        <Form.Item
          name="id"
          label="ID"
          hidden
        >
          <Input disabled />
        </Form.Item>
        
        <Form.Item
          name="nickname"
          label="닉네임"
        >
          <Input placeholder="사용자 닉네임을 입력하세요" />
        </Form.Item>
        
        <Form.Item
          name="email"
          label="이메일"
          rules={[{ type: 'email', message: '유효한 이메일 주소를 입력하세요' }]}
        >
          <Input placeholder="이메일 주소를 입력하세요" />
        </Form.Item>
        
        <Form.Item
          name="avatar_url"
          label="프로필 이미지 URL"
        >
          <Input placeholder="프로필 이미지 URL을 입력하세요" />
        </Form.Item>
        
        <Form.Item
          name="star_candy"
          label="스타캔디"
          rules={[{ required: true, message: '스타캔디 값을 입력하세요' }]}
        >
          <InputNumber min={0} />
        </Form.Item>
        
        <Form.Item
          name="star_candy_bonus"
          label="스타캔디 보너스"
          rules={[{ required: true, message: '스타캔디 보너스 값을 입력하세요' }]}
        >
          <InputNumber min={0} />
        </Form.Item>
        
        <Form.Item
          name="gender"
          label="성별"
        >
          <Select
            options={genderOptions}
            placeholder="성별을 선택하세요"
            allowClear
          />
        </Form.Item>
        
        <Form.Item
          name="birth_date"
          label="생년월일"
        >
          <DatePicker placeholder="생년월일을 선택하세요" />
        </Form.Item>
        
        <Form.Item
          name="birth_time"
          label="출생 시간"
        >
          <Input placeholder="출생 시간 (예: 15:30)" />
        </Form.Item>
        
        <Form.Item
          name="open_gender"
          label="성별 공개"
          valuePropName="checked"
        >
          <Switch />
        </Form.Item>
        
        <Form.Item
          name="open_ages"
          label="나이 공개"
          valuePropName="checked"
        >
          <Switch />
        </Form.Item>
        
        <Form.Item
          name="is_admin"
          label="관리자 권한"
          valuePropName="checked"
        >
          <Switch />
        </Form.Item>
        
        <Form.Item
          name="deleted_at"
          label="계정 상태"
          hidden={!record?.deleted_at}
        >
          <Input disabled value="탈퇴된 계정" />
        </Form.Item>
      </Form>
    </Edit>
  );
} 