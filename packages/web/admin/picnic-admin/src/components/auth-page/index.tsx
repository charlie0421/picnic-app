'use client';
import { AuthPage as AuthPageBase } from '@refinedev/antd';
import type { AuthPageProps } from '@refinedev/core';
import Image from 'next/image';
import React, { useEffect } from 'react';

export const AuthPage = (props: AuthPageProps) => {
  // Refine 배너 제거를 위한 useEffect
  useEffect(() => {
    // GitHub 스타 관련 배너 제거
    const bannerElement = document.querySelector('.refine-banner');
    if (bannerElement) {
      bannerElement.remove();
    }

    // 다른 가능한 배너 선택자들 제거
    const possibleBanners = document.querySelectorAll(
      '[data-testid="refine-banner"], .refine-header, .refine-top-banner',
    );
    possibleBanners.forEach((element) => {
      element.remove();
    });
  }, []);

  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
        padding: '20px',
        // 배너 숨김을 위한 오버플로우 숨김 설정
        overflow: 'hidden',
      }}
    >
      {/* 리파인 배너를 숨기기 위한 전역 스타일 */}
      <style jsx global>{`
        .refine-banner,
        [data-testid='refine-banner'],
        .refine-header,
        .refine-top-banner {
          display: none !important;
        }
      `}</style>

      <div
        style={{
          width: '100%',
          maxWidth: '480px',
          padding: '30px 20px',
          background: 'black',
          borderRadius: '24px',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <AuthPageBase
          {...props}
          type='login'
          wrapperProps={{
            style: {
              background: 'transparent',
              padding: 0,
              width: '100%',
              marginTop: 0,
              marginBottom: 0,
            },
          }}
          contentProps={{
            style: {
              maxHeight: 'none',
              overflow: 'visible',
              background: 'transparent',
              padding: 0,
              width: '100%',
            },
          }}
          formProps={{
            initialValues: {},
            layout: 'vertical',
            style: {
              width: '100%',
              marginBottom: 0,
            },
            wrapperCol: { span: 24 },
            labelCol: { span: 24 },
          }}
          renderContent={(content: any) => {
            if (!content?.props?.children) {
              return <div>{content}</div>;
            }

            // 회원가입 관련 문구가 있는지 재귀적으로 확인하는 함수
            const hasSignUpText = (element: any): boolean => {
              if (!element) return false;

              // 문자열 체크
              if (typeof element === 'string') {
                return (
                  element.includes("Don't have an account?") ||
                  element.includes('Sign up')
                );
              }

              // props 체크
              if (element.props) {
                // children 체크
                const children = element.props.children;

                if (Array.isArray(children)) {
                  return children.some((child) => hasSignUpText(child));
                } else {
                  return hasSignUpText(children);
                }
              }

              return false;
            };

            // 회원가입 관련 요소 제거
            const filteredChildren = content.props.children.filter(
              (child: any) => {
                if (!child) return false;
                if (!child.props) return true;

                // footer 클래스를 가진 요소 제거
                if (
                  child.props.className &&
                  child.props.className.includes('footer')
                )
                  return false;

                // 회원가입 문구가 포함된 요소 제거
                return !hasSignUpText(child);
              },
            );

            return (
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  width: '100%',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    width: '100%',
                    marginBottom: '16px',
                  }}
                >
                  <Image
                    src='/icons/app_icon.png'
                    alt='Picnic Admin'
                    width={140}
                    height={140}
                    style={{
                      borderRadius: '28px',
                      boxShadow: '0 6px 20px rgba(0, 0, 0, 0.2)',
                    }}
                  />
                  <div
                    style={{
                      fontSize: '30px',
                      fontWeight: '900',
                      color: '#ffffff',
                      margin: 0,
                      letterSpacing: '-0.5px',
                      textShadow: '0 2px 4px rgba(0, 0, 0, 0.3)',
                      fontFamily:
                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
                      lineHeight: '1.2',
                      textAlign: 'center',
                      background:
                        'linear-gradient(135deg, #1a1a1a 0%, #333333 100%)',
                      borderRadius: '14px',
                      padding: '8px 24px',
                      marginTop: '16px',
                    }}
                  >
                    Picnic Admin
                  </div>
                </div>
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    width: '100%',
                    marginTop: '8px',
                  }}
                >
                  {filteredChildren.map((child: any, index: number) => {
                    // 입력 필드와 버튼에 너비 100% 적용
                    if (child?.props?.className?.includes('ant-form-item')) {
                      return {
                        ...child,
                        props: {
                          ...child.props,
                          style: {
                            ...child.props.style,
                            width: '100%',
                            marginBottom: '12px',
                          },
                        },
                      };
                    }
                    return child;
                  })}
                </div>
                <div
                  style={{
                    textAlign: 'center',
                    color: '#666666',
                    fontSize: '13px',
                    fontFamily:
                      '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
                    marginTop: '12px',
                    width: '100%',
                  }}
                >
                  Copyright Icon Casting INC.
                </div>
              </div>
            );
          }}
        />
      </div>
    </div>
  );
};
