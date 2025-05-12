'use client';

import { useRouter } from 'next/navigation';
import { Create, useForm } from '@refinedev/antd';
import { message, Button } from 'antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PopupForm from '../components/PopupForm';
import { convertFormDataToPopup } from '@/lib/types/popup';

export default function PopupCreate() {
  const router = useRouter();
  const { formProps, saveButtonProps } = useForm({
    resource: 'popup',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
  });
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  formProps.onFinish = async (values: any) => {
    const transformedValues = convertFormDataToPopup(values);
    return transformedValues;
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
        saveButtonProps={saveButtonProps}
      >
        {contextHolder}
        <PopupForm formProps={{ ...formProps, initialValues }} />
      </Create>
    </AuthorizePage>
  );
}
