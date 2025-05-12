'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message, Button } from 'antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PopupForm from '../../components/PopupForm';
import { useParams, useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function PopupEdit() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;
  const { formProps, saveButtonProps } = useForm({
    resource: 'popup',
    id,
    warnWhenUnsavedChanges: true,
    redirect: 'list',
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  const handleSave = async (values: any) => {
    console.log(values);
    const makeLocaleObj = (prefix: string) =>
      ['ko', 'en', 'ja', 'zh', 'id'].reduce((acc, locale) => {
        const v = values[`${prefix}_${locale}`];
        if (v !== undefined && v !== '') acc[locale] = v;
        return acc;
      }, {} as Record<string, string>);

    const title = makeLocaleObj('title');
    const content = makeLocaleObj('content');
    const image = makeLocaleObj('image');

    return {
      title,
      content,
      image,
      start_at: values.start_at,
      stop_at: values.stop_at,
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

    console.log(result);
    return result;
  };

  const initialValues = convertInitialValues(formProps.initialValues);

  useEffect(() => {
    if (formProps.form && initialValues) {
      formProps.form.setFieldsValue(initialValues);
    }
  }, [formProps.form, initialValues]);

  return (
    <AuthorizePage resource='popup' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
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
      </Edit>
    </AuthorizePage>
  );
}
