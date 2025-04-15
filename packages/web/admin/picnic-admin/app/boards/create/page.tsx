'use client';

import { Create, useForm } from '@refinedev/antd';
import {
  Form,
  message,
  Input,
  Switch,
  Select,
  InputNumber,
  Space,
  Button,
  Tag,
} from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { BoardCreateInput } from '../components/types';
import { MultiLanguageInput } from '@/components/ui';
import { useState } from 'react';

export default function BoardCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  const [features, setFeatures] = useState<string[]>([]);
  const [inputFeature, setInputFeature] = useState('');

  const { formProps, saveButtonProps } = useForm({
    resource: 'boards',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('게시판이 성공적으로 생성되었습니다');
    },
    meta: {
      idField: 'board_id',
    },
  });

  // 저장 전 데이터 변환
  const handleSave = async (values: any) => {
    const transformedValues: BoardCreateInput = {
      ...values,
      features: features,
    };
    return transformedValues;
  };

  // 기능(features) 추가
  const addFeature = () => {
    if (inputFeature && !features.includes(inputFeature)) {
      setFeatures([...features, inputFeature]);
      setInputFeature('');
    }
  };

  // 기능(feature) 삭제
  const removeFeature = (feature: string) => {
    setFeatures(features.filter((item) => item !== feature));
  };

  return (
    <AuthorizePage resource='boards' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label || '게시판 생성'}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: async () => {
            const values = await formProps.form?.validateFields();
            if (values) {
              const transformedValues = await handleSave(values);
              formProps.onFinish?.(transformedValues);
            }
          },
        }}
      >
        {contextHolder}
        <Form {...formProps} layout='vertical'>
          <MultiLanguageInput name='name' label='게시판 이름' required={true} />

          <Form.Item name='description' label='설명'>
            <Input.TextArea rows={4} />
          </Form.Item>

          <Form.Item name='parent_board_id' label='상위 게시판 ID'>
            <Input />
          </Form.Item>

          <Form.Item
            name='is_official'
            label='공식 게시판'
            valuePropName='checked'
            initialValue={false}
          >
            <Switch />
          </Form.Item>

          <Form.Item name='creator_id' label='생성자 ID'>
            <Input />
          </Form.Item>

          <Form.Item
            name='artist_id'
            label='아티스트 ID'
            rules={[{ required: true, message: '아티스트 ID를 입력해주세요' }]}
          >
            <InputNumber style={{ width: '100%' }} min={1} />
          </Form.Item>

          <Form.Item
            name='status'
            label='상태'
            rules={[{ required: true, message: '상태를 선택해주세요' }]}
            initialValue='ACTIVE'
          >
            <Select
              options={[
                { label: '활성', value: 'ACTIVE' },
                { label: '대기중', value: 'PENDING' },
                { label: '거부됨', value: 'REJECTED' },
              ]}
            />
          </Form.Item>

          <Form.Item name='request_message' label='요청 메시지'>
            <Input.TextArea rows={3} />
          </Form.Item>

          <Form.Item name='order' label='순서' initialValue={0}>
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>

          <Form.Item label='기능 목록'>
            <Space direction='vertical' style={{ width: '100%' }}>
              <Space>
                <Input
                  placeholder='기능 입력'
                  value={inputFeature}
                  onChange={(e) => setInputFeature(e.target.value)}
                  onPressEnter={addFeature}
                />
                <Button
                  type='primary'
                  icon={<PlusOutlined />}
                  onClick={addFeature}
                >
                  추가
                </Button>
              </Space>
              <div style={{ marginTop: 8 }}>
                {features.map((feature) => (
                  <Tag
                    key={feature}
                    closable
                    onClose={() => removeFeature(feature)}
                    style={{ margin: '0 8px 8px 0' }}
                  >
                    {feature}
                  </Tag>
                ))}
              </div>
            </Space>
          </Form.Item>
        </Form>
      </Create>
    </AuthorizePage>
  );
}
