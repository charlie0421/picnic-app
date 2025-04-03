'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import { MediaForm } from '@/components/media';

export default function MediaEdit() {
  const { formProps, saveButtonProps, queryResult } = useForm({});
  const [messageApi, contextHolder] = message.useMessage();

  const mediaData = queryResult?.data?.data;

  return (
    <Edit saveButtonProps={saveButtonProps}>
      {contextHolder}
      <MediaForm
        mode='edit'
        id={mediaData?.id?.toString()}
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Edit>
  );
}
