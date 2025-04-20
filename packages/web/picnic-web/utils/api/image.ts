import { supabase } from './supabase';
import { useLanguageStore } from '@/stores/languageStore';

/**
 * CDN 이미지 URL을 생성하는 유틸리티 함수
 * 
 * @param path 이미지 경로
 * @param width 이미지 너비
 * @returns CDN 이미지 URL
 */
export const getCdnImageUrl = (
  path: string | null | undefined,
  width?: number
): string => {
  if (!path) return '';
  
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL || '';
  const currentLang = useLanguageStore.getState().currentLang;
  
  // 이미 전체 URL인 경우 그대로 반환
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  try {
    // JSON 형식의 다국어 경로인지 확인
    if (path.startsWith('{') && path.includes('":')) {
      const pathObj = JSON.parse(path);
      // 현재 언어의 경로가 있으면 사용, 없으면 영어나 한국어 순서로 시도
      const localizedPath = pathObj[currentLang] || pathObj.en || pathObj.ko || Object.values(pathObj)[0];
      
      // 슬래시로 시작하는지 확인
      const normalizedPath = localizedPath.startsWith('/') ? localizedPath.substring(1) : localizedPath;
      
      // 최종 URL 생성
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
  
  // 최종 URL 생성
  const widthParam = width ? `?w=${width}` : '';
  const finalUrl = `${cdnUrl}/${normalizedPath}${widthParam}`;
  
  return finalUrl;
};

export const getLocalizedString = (value: { [key: string]: string } | string | null): string | undefined => {
  if (!value) return undefined;
  if (typeof value === 'string') return value;
  const currentLang = useLanguageStore.getState().currentLang;
  return value[currentLang] || value.en || undefined;
}; 