import { MultilingualText } from './common';
export type { MultilingualText };
import { supportedLocales } from '@/lib/utils/translation';

export interface Notice {
  id: string;
  title: MultilingualText;
  content: MultilingualText;
  status: 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
}

// 단일 언어로 표시하는 Notice (UI 표시용)
export interface DisplayNotice extends Omit<Notice, 'title' | 'content'> {
  title: string;
  content: string;
}

// Notice 폼 데이터 (입력용)
export interface NoticeFormData {
  title_ko: string;
  title_en: string;
  title_ja: string;
  title_zh: string;
  title_id: string;
  content_ko: string;
  content_en: string;
  content_ja: string;
  content_zh: string;
  content_id: string;
  status: 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
  is_pinned: boolean;
}

export const convertNoticeToFormData = (notice: Notice): NoticeFormData => {
  const result: any = {};
  if (notice?.title) {
    supportedLocales.forEach((locale) => {
      result[`title_${locale}`] = notice.title[locale] || '';
    });
  }
  if (notice?.content) {
    supportedLocales.forEach((locale) => {
      result[`content_${locale}`] = notice.content[locale] || '';
    });
  }
  result.status = notice.status;
  result.is_pinned = notice.is_pinned;
  return result;
};

export function convertFormDataToNotice(
  formData: any,
): Omit<Notice, 'id' | 'created_at'> {
  const title: MultilingualText = {} as MultilingualText;
  const content: MultilingualText = {} as MultilingualText;
  supportedLocales.forEach((locale) => {
    title[locale] = formData[`title_${locale}`] || '';
    content[locale] = formData[`content_${locale}`] || '';
  });
  return {
    title,
    content,
    status: formData.status,
    is_pinned: formData.is_pinned,
    updated_at: new Date().toISOString(),
  };
}
