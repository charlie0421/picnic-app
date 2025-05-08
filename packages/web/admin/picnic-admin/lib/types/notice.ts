import { MultilingualText } from './common';
export type { MultilingualText };

export interface Notice {
  id: string;
  title: MultilingualText;
  content: MultilingualText;
  status: 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
  is_pinned: boolean;
  created_by: string;
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
