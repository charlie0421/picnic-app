'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, message, Input, Switch, Select, Upload, Button } from 'antd';
import { UploadOutlined } from '@ant-design/icons';
import { useParams } from 'next/navigation';
import { useResource, useOne } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { PostUpdateInput, Post } from '../../../../lib/types/post';
import React, { useState, useEffect } from 'react';

export default function PostEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();
  const [fileList, setFileList] = useState<any[]>([]);

  // 게시글 데이터 조회
  const { data } = useOne<Post>({
    resource: 'posts',
    id,
    meta: {
      idField: 'post_id',
    },
  });

  useEffect(() => {
    // 첨부파일 목록 초기화
    if (data?.data?.attachments) {
      const initialFileList = data.data.attachments.map((url, index) => ({
        uid: `-${index}`,
        name: url.split('/').pop(),
        status: 'done',
        url,
      }));
      setFileList(initialFileList);
    }
  }, [data]);

  const { formProps, saveButtonProps } = useForm({
    resource: 'posts',
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    errorNotification: (error) => ({
      message: '오류가 발생했습니다.',
      description: error?.message || '알 수 없는 오류가 발생했습니다.',
      type: 'error',
    }),
    onMutationSuccess: () => {
      messageApi.success('게시글이 성공적으로 수정되었습니다');
    },
    meta: {
      idField: 'post_id',
    },
  });

  // 저장 전 데이터 변환
  const handleSave = async (values: any) => {
    const transformedValues: PostUpdateInput = {
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
    <AuthorizePage resource='posts' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label || '게시글 수정'}
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
            <Input disabled />
          </Form.Item>

          <Form.Item
            name='is_anonymous'
            label='익명 여부'
            valuePropName='checked'
          >
            <Switch />
          </Form.Item>

          <Form.Item name='is_hidden' label='숨김 여부' valuePropName='checked'>
            <Switch />
          </Form.Item>

          <Form.Item
            name='is_temporary'
            label='임시 저장'
            valuePropName='checked'
          >
            <Switch />
          </Form.Item>

          <Form.Item label='첨부 파일'>
            <Upload {...uploadProps}>
              <Button icon={<UploadOutlined />}>파일 선택</Button>
            </Upload>
          </Form.Item>
        </Form>
      </Edit>
    </AuthorizePage>
  );
}
