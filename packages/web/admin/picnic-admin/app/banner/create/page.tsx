'use client';

import { useRouter } from 'next/navigation';
import { message } from 'antd';
import BannerForm from '../components/BannerForm';
import { Create } from '@refinedev/antd';
import { useCreate, useResource } from '@refinedev/core';
import { useForm } from '@refinedev/antd';
import { Banner } from '@/lib/types/banner';

export default function CreateBannerPage() {
  const { resource } = useResource();
  const [messageApi, contextHolder] = message.useMessage();

  const { mutate: createBanner } = useCreate();

  const { formProps, saveButtonProps } = useForm<Banner>({
    resource: 'banner',
    redirect: 'list',
    onMutationSuccess: (data) => {
      messageApi.success('배너가 성공적으로 생성되었습니다');
    },
  });

  return (
    <Create
      breadcrumb={false}
      goBack={false}
      title={resource?.meta?.create?.label}
      saveButtonProps={{
        ...saveButtonProps,
        onClick: async () => {
          const values = await formProps.form?.validateFields();
          if (values) {
            formProps.onFinish?.(values);
          }
        },
      }}
    >
      {contextHolder}
      <BannerForm
        mode='create'
        formProps={formProps}
        saveButtonProps={saveButtonProps}
      />
    </Create>
  );
}
