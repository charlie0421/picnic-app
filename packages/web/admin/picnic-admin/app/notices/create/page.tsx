'use client';

import { Create, useForm } from '@refinedev/antd';
import { Button } from 'antd';
import { useGetIdentity, useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import { Notice, NoticeFormData } from '@/lib/types/notice';
import { NoticeForm } from '../components/NoticeForm';

// FormData를 Notice로 변환
const convertFormDataToNotice = (formData: NoticeFormData): Partial<Notice> => {
  return {
    title: {
      ko: formData.title_ko,
      en: formData.title_en,
      ja: formData.title_ja,
      zh: formData.title_zh,
      id: formData.title_id,
    },
    content: {
      ko: formData.content_ko,
      en: formData.content_en,
      ja: formData.content_ja,
      zh: formData.content_zh,
      id: formData.content_id,
    },
    status: formData.status,
    is_pinned: formData.is_pinned,
  };
};

export default function NoticeCreatePage() {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, onFinish } = useForm<NoticeFormData>({
    resource: 'notices',
    redirect: 'list',
  });

  const { data: identity } = useGetIdentity<{ id: string }>();

  useEffect(() => {
    // 폼 초기값 설정
    formProps.form?.setFieldsValue({
      status: 'DRAFT', // 기본값 초안
      is_pinned: false, // 기본값 일반 공지
    });
  }, [formProps.form]);

  // 폼 제출 핸들러
  const handleSubmit = async (values: NoticeFormData) => {
    const submitData = convertFormDataToNotice(values);

    // 현재 사용자 ID 추가
    const finalData = {
      ...submitData,
      created_by: identity?.id,
    };

    return onFinish(finalData);
  };

  return (
    <AuthorizePage resource='notices' action='create'>
      <Create
        title='공지사항 작성'
        footerButtons={
          <>
            <Button onClick={goBack}>취소</Button>
            <Button type='primary' {...saveButtonProps}>
              저장
            </Button>
          </>
        }
      >
        <NoticeForm formProps={formProps} onSubmit={handleSubmit} />
      </Create>
    </AuthorizePage>
  );
}
