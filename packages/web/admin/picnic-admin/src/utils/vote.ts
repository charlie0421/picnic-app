import type { SelectProps } from 'antd';

// 투표 상태 정의
export const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

export type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];
export type VoteCategory = 'birthday' | 'debut' | 'achieve';

// 투표 카테고리 정의
export const VOTE_CATEGORIES: SelectProps['options'] = [
  { label: '생일', value: 'birthday' },
  { label: '데뷔', value: 'debut' },
  { label: '누적', value: 'achieve' },
];

// 투표 상태 태그 색상
export const STATUS_TAG_COLORS: Record<VoteStatus, string> = {
  [VOTE_STATUS.UPCOMING]: 'blue',
  [VOTE_STATUS.ONGOING]: 'green',
  [VOTE_STATUS.COMPLETED]: 'default',
};

// 투표 상태별 배경 색상 정의 (다크모드 고려)
export const STATUS_COLORS: Record<VoteStatus, string> = {
  [VOTE_STATUS.UPCOMING]: 'rgba(24, 144, 255, 0.15)', // 진한 파란색 배경
  [VOTE_STATUS.ONGOING]: 'rgba(82, 196, 26, 0.15)', // 진한 초록색 배경
  [VOTE_STATUS.COMPLETED]: 'rgba(140, 140, 140, 0.15)', // 진한 회색 배경
};

// 다국어 제목 인터페이스
export interface MultilingualTitle {
  ko?: string;
  en?: string;
  ja?: string;
  zh?: string;
}

// 투표 상태 계산 함수
export const getVoteStatus = (
  startDate?: string,
  endDate?: string,
  now?: Date,
): VoteStatus => {
  if (!startDate || !endDate) return VOTE_STATUS.UPCOMING;

  const currentDate = now || new Date();
  const start = new Date(startDate);
  const end = new Date(endDate);

  if (currentDate < start) return VOTE_STATUS.UPCOMING;
  if (currentDate > end) return VOTE_STATUS.COMPLETED;
  return VOTE_STATUS.ONGOING;
};

// 투표 레코드 인터페이스
export interface VoteRecord {
  id?: string;
  vote_category?: VoteCategory;
  category?: VoteCategory;
  title?: MultilingualTitle;
  visible_at?: string;
  start_at?: string;
  stop_at?: string;
  main_image?: string;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string;
  vote_item?: any[];
  vote?: {
    id: string;
    [key: string]: any;
  };
}
