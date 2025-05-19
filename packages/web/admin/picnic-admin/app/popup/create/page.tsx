'use client';

import { useRouter } from 'next/navigation';
import { Create, useForm } from '@refinedev/antd';
import { message, Button } from 'antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PopupForm from '../components/PopupForm';
import {
  convertFormDataToPopup,
  convertPopupToFormData,
  Popup,
} from '@/lib/types/popup';
import { useEffect } from 'react';

export default function PopupCreate() {
  const { formProps, saveButtonProps } = useForm({
    resource: 'popup',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
  });
  const { resource } = useResource();

  useEffect(() => {
    if (formProps.form && formProps.initialValues) {
      const formData = convertPopupToFormData(formProps.initialValues as Popup);
      formProps.form.setFieldsValue(formData);
      setTimeout(() => {
        if (formProps.form) {
          formProps.form.setFieldsValue(formData);
        }
      }, 500);
    }
  }, [formProps.form, formProps.initialValues]);

  const handleSubmit = async () => {
    const values = formProps.form?.getFieldsValue();
    console.log(values);
    const submitData = convertFormDataToPopup(values);
    console.log(submitData);
    return formProps.onFinish?.(submitData);
  };

  return (
    <AuthorizePage resource='popup' action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: handleSubmit,
        }}
      >
        <PopupForm formProps={{ ...formProps }} />
      </Create>
    </AuthorizePage>
  );
}
