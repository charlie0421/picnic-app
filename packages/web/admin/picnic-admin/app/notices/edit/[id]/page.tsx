'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Button } from 'antd';
import { useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { Notice, NoticeFormData, MultilingualText } from '@/lib/types/notice';
import { useEffect } from 'react';
import { NoticeForm } from '../../components/NoticeForm';

// MultilingualText 타입 가드
const isMultilingualText = (value: any): value is MultilingualText => {
  return typeof value === 'object' && value !== null && 'ko' in value;
};

// 문자열을 MultilingualText로 변환
const toMultilingualText = (
  value: string | MultilingualText,
): MultilingualText => {
  if (isMultilingualText(value)) {
    return value;
  }
  try {
    const parsed = JSON.parse(value);
    if (isMultilingualText(parsed)) {
      return parsed;
    }
  } catch {
    // JSON 파싱 실패 시 기본값 반환
  }
  return {
    ko: value,
    en: value,
    ja: value,
    zh: value,
    id: value,
  };
};

// Notice를 FormData로 변환
const convertNoticeToFormData = (notice: Notice): NoticeFormData => {
  const title = toMultilingualText(notice.title);
  const content = toMultilingualText(notice.content);

  return {
    title_ko: title.ko || '',
    title_en: title.en || '',
    title_ja: title.ja || '',
    title_zh: title.zh || '',
    title_id: title.id || '',
    content_ko: content.ko || '',
    content_en: content.en || '',
    content_ja: content.ja || '',
    content_zh: content.zh || '',
    content_id: content.id || '',
    status: notice.status,
    is_pinned: notice.is_pinned,
  };
};

export default function NoticeEditPage({ params }: { params: { id: string } }) {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult, onFinish } =
    useForm<NoticeFormData>({
      resource: 'notices',
      id: params.id,
      redirect: 'list',
      meta: {
        select:
          'id, title, content, status, is_pinned, created_by, created_at, updated_at',
      },
    });

  // 데이터 로드 후 폼 필드 설정
  useEffect(() => {
    if (queryResult?.data?.data) {
      const notice = queryResult.data.data as unknown as Notice;
      const formData = convertNoticeToFormData(notice);
      formProps.form?.setFieldsValue(formData);
    }
  }, [queryResult?.data?.data, formProps.form]);

  // 폼 제출 핸들러
  const handleSubmit = async (values: NoticeFormData) => {
    // 현재 폼의 모든 값을 가져옴
    const formValues = formProps.form?.getFieldsValue() as NoticeFormData;

    const submitData = {
      title: {
        ko: formValues?.title_ko || values.title_ko,
        en: formValues?.title_en || values.title_en,
        ja: formValues?.title_ja || values.title_ja,
        zh: formValues?.title_zh || values.title_zh,
        id: formValues?.title_id || values.title_id,
      },
      content: {
        ko: formValues?.content_ko || values.content_ko,
        en: formValues?.content_en || values.content_en,
        ja: formValues?.content_ja || values.content_ja,
        zh: formValues?.content_zh || values.content_zh,
        id: formValues?.content_id || values.content_id,
      },
      status: values.status,
      is_pinned: values.is_pinned,
      updated_at: new Date().toISOString(),
    };
    return onFinish(submitData);
  };

  return (
    <AuthorizePage resource='notices' action='edit'>
      <Edit
        title='공지사항 수정'
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
      </Edit>
    </AuthorizePage>
  );
}
