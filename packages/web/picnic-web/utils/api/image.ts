import { supabase } from './supabase';

/**
 * CDN 이미지 URL을 생성하는 유틸리티 함수
 * 
 * @param path 이미지 경로
 * @returns CDN 이미지 URL
 */
export const getCdnImageUrl = (path: string | null | undefined, width?: number): string => {
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
      const widthParam = width ? `?w=${width}` : '';
      const finalUrl = `${cdnUrl}/${normalizedPath}${widthParam}`;
      
      return finalUrl;
    }
  } catch (e) {
    console.error('이미지 경로 파싱 오류:', e);
    // JSON 파싱 실패 시 원래 경로 사용
  }
  
  // 슬래시로 시작하는지 확인
  const normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  
  // 최종 URL 생성 전에 콘솔에 로그
  const widthParam = width ? `?w=${width}` : '';
  const finalUrl = `${cdnUrl}/${normalizedPath}${widthParam}`;
  console.log('생성된 CDN URL:', finalUrl);
  
  return finalUrl;
};

export const getLocalizedString = (value: { [key: string]: string } | null): string | undefined => {
  if (!value) return undefined;
  return value.ko || value.en || undefined;
}; 