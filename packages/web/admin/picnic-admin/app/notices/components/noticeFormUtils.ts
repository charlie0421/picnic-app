// FormData를 Notice로 변환
import { Notice, NoticeFormData } from '@/lib/types/notice';

export const convertFormDataToNotice = (formData: NoticeFormData): Partial<Notice> => {
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