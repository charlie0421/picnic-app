'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, Input, InputNumber, Switch, Select, DatePicker, message } from 'antd';
import { genderOptions } from './types';
import { useResource } from '@refinedev/core';

interface UserProfileCreateProps {
  resource?: string;
}

export function UserProfileCreate({ resource = 'user_profiles' }: UserProfileCreateProps) {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource: resourceInfo } = useResource();

  const { formProps, saveButtonProps } = useForm({
    resource,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('사용자가 성공적으로 생성되었습니다');
    },
  });

  return (
    <Create
      breadcrumb={false}
      title="새 사용자 생성"
      saveButtonProps={saveButtonProps}
    >
      {contextHolder}
      <Form {...formProps} layout="vertical">
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
          initialValue={0}
          rules={[{ required: true, message: '스타캔디 값을 입력하세요' }]}
        >
          <InputNumber min={0} />
        </Form.Item>
        
        <Form.Item
          name="star_candy_bonus"
          label="스타캔디 보너스"
          initialValue={0}
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
          initialValue={true}
        >
          <Switch />
        </Form.Item>
        
        <Form.Item
          name="open_ages"
          label="나이 공개"
          valuePropName="checked"
          initialValue={true}
        >
          <Switch />
        </Form.Item>
        
        <Form.Item
          name="is_admin"
          label="관리자 권한"
          valuePropName="checked"
          initialValue={false}
        >
          <Switch />
        </Form.Item>
      </Form>
    </Create>
  );
} 