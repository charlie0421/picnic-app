/**
 * CDN 이미지 URL을 생성하는 유틸리티 함수
 * 
 * @param path 이미지 경로
 * @returns CDN 이미지 URL
 */
export const getCdnImageUrl = (path: string | null | undefined): string => {
  if (!path) return '';
  
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL || '';
  
  // 이미 전체 URL인 경우 그대로 반환
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  try {
    // JSON 형식의 다국어 경로인지 확인
    if (path.startsWith('{') && path.includes('":')) {
      const pathObj = JSON.parse(path);
      // 한국어 경로가 있으면 한국어 경로 사용, 없으면 첫 번째 경로 사용
      const koPath = pathObj.ko || Object.values(pathObj)[0];
      
      // 슬래시로 시작하는지 확인
      const normalizedPath = koPath.startsWith('/') ? koPath.substring(1) : koPath;
      
      // 최종 URL 생성 전에 콘솔에 로그
      const finalUrl = `${cdnUrl}/${normalizedPath}`;
      
      return finalUrl;
    }
  } catch (e) {
    console.error('이미지 경로 파싱 오류:', e);
    // JSON 파싱 실패 시 원래 경로 사용
  }
  
  // 슬래시로 시작하는지 확인
  const normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  
  // 최종 URL 생성 전에 콘솔에 로그
  const finalUrl = `${cdnUrl}/${normalizedPath}`;
  // console.log('생성된 CDN URL:', finalUrl);
  
  return finalUrl;
};

/**
 * 투표 관련 이미지 URL 생성 함수
 * 
 * @param voteId 투표 ID
 * @param imagePath 이미지 파일명
 * @returns 투표 이미지 CDN URL
 */
export const getVoteImageUrl = (voteId: string | number, imagePath: string | null | undefined): string => {
  if (!imagePath) return '';
  
  // 이미 전체 경로인 경우
  if (imagePath.includes('vote/')) {
    const parts = imagePath.split('/');
    const voteIdInPath = parts[parts.indexOf('vote') + 1];
    
    // 경로에 이미 해당 투표 ID가 포함되어 있는 경우
    if (voteIdInPath === voteId.toString()) {
      return getCdnImageUrl(imagePath);
    }
  }
  
  return getCdnImageUrl(`vote/${voteId}/${imagePath}`);
};

/**
 * 배너 이미지 URL 생성 함수
 * 
 * @param imagePath 이미지 파일명 또는 경로
 * @returns 배너 이미지 CDN URL
 */
export const getBannerImageUrl = (imagePath: string | null | undefined): string => {
  if (!imagePath) return '';
  
  // JSON 형식인지 확인 (다국어 지원)
  if (imagePath.startsWith('{') && imagePath.includes('":')) {
    return getCdnImageUrl(imagePath);
  }
  
  // 이미 banner/ 경로가 포함된 경우 (중복 방지)
  if (imagePath.includes('banner/')) {
    return getCdnImageUrl(imagePath);
  }
  
  // 단순 파일명만 있는 경우 완전한 경로 생성
  return getCdnImageUrl(`banner/${imagePath}`);
};

/**
 * 리워드 이미지 URL 생성 함수
 * 
 * @param imagePath 이미지 파일명 또는 경로
 * @returns 리워드 이미지 CDN URL
 */
export const getRewardImageUrl = (imagePath: string | null | undefined): string => {
  if (!imagePath) return '';
  
  // JSON 형식인지 확인 (다국어 지원)
  if (imagePath.startsWith('{') && imagePath.includes('":')) {
    return getCdnImageUrl(imagePath);
  }
  
  // 이미 reward/ 경로가 포함된 경우 (중복 방지)
  if (imagePath.includes('reward/')) {
    return getCdnImageUrl(imagePath);
  }
  
  // 단순 파일명만 있는 경우 완전한 경로 생성
  return getCdnImageUrl(`reward/${imagePath}`);
};

export const getLocalizedImage = (image: any): string => {
  if (typeof image === 'object' && !Array.isArray(image) && 'ko' in image) {
    return image.ko as string;
  }
  return String(image);
}; 