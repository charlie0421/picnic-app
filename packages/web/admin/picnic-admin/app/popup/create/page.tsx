'use client';

import { useRouter } from 'next/navigation';
import { Create, useForm } from '@refinedev/antd';
import { message, Button } from 'antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PopupForm from '../components/PopupForm';

export default function PopupCreate() {
  const router = useRouter();
  const { formProps, saveButtonProps } = useForm({
    resource: 'popup',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const handleSave = async (values: any) => {
    const title = {
      ko: values.title_ko,
      en: values.title_en,
      ja: values.title_ja,
      zh: values.title_zh,
      id: values.title_id,
    };
    const content = {
      ko: values.content_ko,
      en: values.content_en,
      ja: values.content_ja,
      zh: values.content_zh,
      id: values.content_id,
    };
    const image = {
      ko: values.image?.ko || undefined,
      en: values.image?.en || undefined,
      ja: values.image?.ja || undefined,
      zh: values.image?.zh || undefined,
      id: values.image?.id || undefined,
    };
    return {
      title,
      content,
      image,
      start_at: values.start_at?.toISOString(),
      stop_at: values.stop_at?.toISOString(),
    };
  };

  const convertInitialValues = (values: any) => {
    if (!values) return values;
    const result = { ...values };
    if (values.title) {
      Object.entries(values.title).forEach(([locale, value]) => {
        result[`title_${locale}`] = value;
      });
    }
    if (values.content) {
      Object.entries(values.content).forEach(([locale, value]) => {
        result[`content_${locale}`] = value;
      });
    }
    return result;
  };

  const initialValues = convertInitialValues(formProps.initialValues);

  return (
    <AuthorizePage resource='popup' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        headerButtons={({ defaultButtons }) => (
          <Button onClick={() => router.push('/popup')}>목록으로</Button>
        )}
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
        <PopupForm formProps={{ ...formProps, initialValues }} />
      </Create>
    </AuthorizePage>
  );
}
