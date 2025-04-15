'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, message, Input, Switch, Select, Upload, Button } from 'antd';
import { InboxOutlined, UploadOutlined } from '@ant-design/icons';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { PostCreateInput } from '../components/types';
import React, { useState } from 'react';

export default function PostCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  const [fileList, setFileList] = useState<any[]>([]);

  const { formProps, saveButtonProps } = useForm({
    resource: 'posts',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('게시글이 성공적으로 생성되었습니다');
    },
    meta: {
      idField: 'post_id',
    },
  });

  // 저장 전 데이터 변환
  const handleSave = async (values: any) => {
    const transformedValues: PostCreateInput = {
      ...values,
      attachments: fileList.map((file) => file.name || file.url),
    };
    return transformedValues;
  };

  const uploadProps = {
    onRemove: (file: any) => {
      const index = fileList.indexOf(file);
      const newFileList = fileList.slice();
      newFileList.splice(index, 1);
      setFileList(newFileList);
    },
    beforeUpload: (file: any) => {
      setFileList([...fileList, file]);
      return false;
    },
    fileList,
  };

  return (
    <AuthorizePage resource='posts' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label || '게시글 생성'}
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
          <Form.Item
            name='title'
            label='제목'
            rules={[{ required: true, message: '제목을 입력해주세요' }]}
          >
            <Input />
          </Form.Item>

          <Form.Item
            name='content'
            label='내용'
            rules={[{ required: true, message: '내용을 입력해주세요' }]}
          >
            <Input.TextArea rows={6} />
          </Form.Item>

          <Form.Item name='board_id' label='게시판'>
            <Select
              placeholder='게시판 선택'
              allowClear
              options={
                [
                  // 게시판 옵션은 실제 데이터로 교체 필요
                ]
              }
            />
          </Form.Item>

          <Form.Item
            name='user_id'
            label='작성자'
            rules={[{ required: true, message: '작성자를 입력해주세요' }]}
          >
            <Input />
          </Form.Item>

          <Form.Item
            name='is_anonymous'
            label='익명 여부'
            valuePropName='checked'
            initialValue={false}
          >
            <Switch />
          </Form.Item>

          <Form.Item
            name='is_hidden'
            label='숨김 여부'
            valuePropName='checked'
            initialValue={false}
          >
            <Switch />
          </Form.Item>

          <Form.Item
            name='is_temporary'
            label='임시 저장'
            valuePropName='checked'
            initialValue={false}
          >
            <Switch />
          </Form.Item>

          <Form.Item label='첨부 파일'>
            <Upload {...uploadProps}>
              <Button icon={<UploadOutlined />}>파일 선택</Button>
            </Upload>
          </Form.Item>
        </Form>
      </Create>
    </AuthorizePage>
  );
}
