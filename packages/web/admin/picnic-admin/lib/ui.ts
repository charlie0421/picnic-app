import { theme } from 'antd';
import { CSSProperties } from 'react';
import { COLORS } from './theme';

type ThemeToken = ReturnType<typeof theme.useToken>['token'];

/**
 * 테마에 기반한 UI 스타일링을 위한 유틸리티 함수들
 */

// 카드 스타일 생성 함수
export const getCardStyle = (
  token: ThemeToken,
  isMobile = false,
  extraStyles = {},
) => {
  const shadowColor = `rgba(0, 0, 0, ${
    token.colorBgMask === '#000000' ? 0.15 : 0.08
  })`;

  return {
    background: token.colorBgContainer,
    borderRadius: '12px',
    boxShadow: `0 4px 12px ${shadowColor}`,
    padding: '24px',
    border: `1px solid ${token.colorBorderSecondary}`,
    color: token.colorText,
    marginBottom: isMobile ? '20px' : '0',
    ...extraStyles,
  };
};

// 섹션 스타일 생성 함수
export const getSectionStyle = (token: ThemeToken, extraStyles = {}) => {
  return {
    marginBottom: '16px',
    background: token.colorBgElevated,
    padding: '12px',
    borderRadius: '8px',
    border: `1px solid ${token.colorBorderSecondary}`,
    ...extraStyles,
  };
};

// 섹션 헤더 스타일 생성 함수
export const getSectionHeaderStyle = (token: ThemeToken, extraStyles = {}) => {
  return {
    marginBottom: '20px',
    ...extraStyles,
  };
};

// 제목 스타일 생성 함수
export const getTitleStyle = (token: ThemeToken, extraStyles = {}) => {
  return {
    margin: '0 0 8px 0',
    color: COLORS.primary,
    ...extraStyles,
  };
};

// 이미지 스타일 생성 함수
export const getImageStyle = (
  token: ThemeToken,
  extraStyles = {},
): CSSProperties => {
  const shadowColor = `rgba(0, 0, 0, ${
    token.colorBgMask === '#000000' ? 0.15 : 0.08
  })`;

  return {
    maxWidth: '100%',
    objectFit: 'contain' as const,
    borderRadius: '8px',
    boxShadow: `0 2px 8px ${shadowColor}`,
    border: `1px solid ${token.colorBorderSecondary}`,
    ...extraStyles,
  };
};

// 날짜 섹션 스타일
export const getDateSectionStyle = (token: ThemeToken, extraStyles = {}) => {
  return {
    marginTop: '32px',
    marginBottom: '16px',
    borderBottom: `2px solid ${COLORS.primary}`,
    paddingBottom: '10px',
    ...extraStyles,
  };
};
