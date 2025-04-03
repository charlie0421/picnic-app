import { FormInstance } from 'antd';

// 미디어 상수 정의
export const MEDIA_TYPES = {
  YOUTUBE: 'youtube',
  VIMEO: 'vimeo',
} as const;

export type MediaType = (typeof MEDIA_TYPES)[keyof typeof MEDIA_TYPES];

// 비디오 ID로 미리보기 업데이트하는 함수
export const updatePreview = (videoId: string, form?: FormInstance) => {
  // 커스텀 썸네일이 있는지 확인
  const customThumbnail = form?.getFieldValue('thumbnail_url');

  if (!videoId || videoId.trim() === '') {
    // 폼 필드도 빈 문자열로 업데이트 (단, 커스텀 썸네일이 있다면 유지)
    form?.setFieldsValue({
      video_id: '',
      video_url: '',
      thumbnail_url: customThumbnail || '', // 커스텀 썸네일이 있으면 유지
    });

    return {
      videoId: '',
      thumbnailUrl: '',
    };
  }

  // 유튜브 ID가 있으면 썸네일 URL 생성
  const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/0.jpg`;

  // URL도 자동으로 구성
  const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

  // 폼 업데이트
  if (form) {
    // 커스텀 썸네일이 없을 경우에만 유튜브 썸네일 사용
    if (!customThumbnail) {
      form.setFieldsValue({
        video_url: videoUrl,
        thumbnail_url: '', // 커스텀 썸네일이 없으면 빈 문자열 (유튜브 썸네일은 자동으로 적용)
      });
    } else {
      // 커스텀 썸네일이 있으면 video_url만 업데이트
      form.setFieldsValue({
        video_url: videoUrl,
      });
    }
  }

  return {
    videoId,
    thumbnailUrl,
  };
};
