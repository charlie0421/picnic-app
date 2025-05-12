'use client';

import { Edit, useForm } from '@refinedev/antd';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import PopupForm from '../../components/PopupForm';
import { useEffect } from 'react';
import { convertPopupToFormData, convertFormDataToPopup, PopupFormData, Popup } from '@/lib/types/popup';

export default function PopupEdit({ params }: { params: { id: string } }) {
  const { formProps, saveButtonProps, onFinish } = useForm({
    resource: 'popup',
    id: params.id,
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
    const submitData = convertFormDataToPopup(values as PopupFormData);
    submitData.updated_at = new Date().toISOString();
    return onFinish(submitData);
  };

  return (
    <AuthorizePage resource={resource?.name} action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: handleSubmit,
        }}
      >
        <PopupForm formProps={{ ...formProps }} />
      </Edit>
    </AuthorizePage>
  );
}
