'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useState } from 'react';
import { PostForm } from '../components';

export default function PostCreatePage() {
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
    return {
      ...values,
      attachments: fileList.map((file) => file.name || file.url),
    };
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
        <PostForm 
          formProps={formProps}
          initialFileList={fileList}
          onSave={(updatedValues) => {
            // 파일 목록 업데이트
            setFileList(updatedValues.attachments.map((name: string) => ({ 
              name, 
              uid: name, 
              status: 'done' 
            })));
            return updatedValues;
          }}
        />
      </Create>
    </AuthorizePage>
  );
}
