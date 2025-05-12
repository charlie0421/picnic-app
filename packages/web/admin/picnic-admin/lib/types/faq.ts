import { SupportedLocale } from '../utils/translation';
import { MultilingualText } from './common';

export interface FAQ {
  id: number;
  question: MultilingualText | string; // 하위 호환성을 위해 문자열도 허용
  answer: MultilingualText | string; // 하위 호환성을 위해 문자열도 허용
  category?: string;
  status: 'PUBLISHED' | 'DRAFT' | 'ARCHIVED';
  order_number: number;
  created_by: string;
  created_at: string;
  updated_at: string;
  created_by_user?: {
    email: string;
    user_metadata?: {
      name?: string;
    };
  };
}

// 단일 언어로 표시하는 FAQ (UI 표시용)
export interface DisplayFAQ extends Omit<FAQ, 'question' | 'answer'> {
  question: string;
  answer: string;
}

// 지정된 로케일로 FAQ를 변환
export function convertToDisplayFAQ(
  faq: FAQ,
  locale: SupportedLocale = 'ko',
): DisplayFAQ {
  return {
    ...faq,
    question:
      typeof faq.question === 'string'
        ? faq.question
        : faq.question?.[locale] || faq.question?.ko || '',
    answer:
      typeof faq.answer === 'string'
        ? faq.answer
        : faq.answer?.[locale] || faq.answer?.ko || '',
  };
}

// FAQ 폼 데이터 (입력용)
export interface FAQFormData {
  question_ko: string;
  question_en: string;
  question_ja: string;
  question_zh: string;
  question_id: string;
  answer_ko: string;
  answer_en: string;
  answer_ja: string;
  answer_zh: string;
  answer_id: string;
  category?: string;
  status: 'PUBLISHED' | 'DRAFT' | 'ARCHIVED';
  order_number: number;
}

// 폼 데이터를 FAQ 객체로 변환
export function convertFormDataToFAQ(
  formData: FAQFormData,
): Omit<
  FAQ,
  'id' | 'created_at' | 'updated_at' | 'created_by' | 'created_by_user'
> {
  const question: MultilingualText = {
    ko: formData.question_ko || '',
    en: formData.question_en || '',
    ja: formData.question_ja || '',
    zh: formData.question_zh || '',
    id: formData.question_id || '',
  };

  const answer: MultilingualText = {
    ko: formData.answer_ko || '',
    en: formData.answer_en || '',
    ja: formData.answer_ja || '',
    zh: formData.answer_zh || '',
    id: formData.answer_id || '',
  };

  return {
    question,
    answer,
    category: formData.category,
    status: formData.status,
    order_number: formData.order_number,
  };
}

// FAQ 객체를 폼 데이터로 변환
export function convertFAQToFormData(faq: FAQ): FAQFormData {
  // 문자열이면 ko 필드에 할당하고, 나머지는 빈 문자열로 초기화
  const questionObj =
    typeof faq.question === 'string'
      ? ({
          ko: faq.question,
          en: '',
          ja: '',
          zh: '',
          id: '',
        } as MultilingualText)
      : faq.question;

  const answerObj =
    typeof faq.answer === 'string'
      ? ({ ko: faq.answer, en: '', ja: '', zh: '', id: '' } as MultilingualText)
      : faq.answer;

  return {
    question_ko: questionObj?.ko || '',
    question_en: questionObj?.en || '',
    question_ja: questionObj?.ja || '',
    question_zh: questionObj?.zh || '',
    question_id: questionObj?.id || '',
    answer_ko: answerObj?.ko || '',
    answer_en: answerObj?.en || '',
    answer_ja: answerObj?.ja || '',
    answer_zh: answerObj?.zh || '',
    answer_id: answerObj?.id || '',
    category: faq.category,
    status: faq.status,
    order_number: faq.order_number,
  };
}
