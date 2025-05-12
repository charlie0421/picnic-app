'use client';

import { Edit, useForm } from '@refinedev/antd';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Notice, NoticeFormData } from '@/lib/types/notice';
import { useEffect } from 'react';
import { NoticeForm } from '../../components/NoticeForm';
import { convertNoticeToFormData, convertFormDataToNotice } from '@/lib/types/notice';
import { useResource } from '@refinedev/core';

export default function NoticeEditPage({ params }: { params: { id: string } }) {
  const { formProps, saveButtonProps, onFinish } = useForm({
    resource: 'notices',
      id: params.id,
      redirect: 'list',
      warnWhenUnsavedChanges: true,
    });

  const { resource } = useResource();

  useEffect(() => {
    if (formProps.form && formProps.initialValues) {
      const formData = convertNoticeToFormData(formProps.initialValues as Notice);
      formProps.form.setFieldsValue(formData);
      setTimeout(() => {
        if (formProps.form) {
          formProps.form.setFieldsValue(formData);
        }
      }, 500);
    }
  }, [formProps.form, formProps.initialValues]);

  // popup 구조처럼 saveButtonProps.onClick에서 직접 제출
  const handleSubmit = async () => {
    const values = formProps.form?.getFieldsValue();
    const submitData = convertFormDataToNotice(values as NoticeFormData);
    submitData.updated_at = new Date().toISOString();
    return onFinish(submitData);
  };

  return (
    <AuthorizePage resource='notices' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: handleSubmit,
        }}
      >
        <NoticeForm formProps={{ ...formProps }} />
      </Edit>
    </AuthorizePage>
  );
}

