'use client';

import { Create, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RewardForm from './RewardForm';
import { useResource } from '@refinedev/core';
import { Reward } from './types';

export default function RewardCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource: resourceInfo } = useResource();

  const { formProps, saveButtonProps } = useForm<Reward>({
    resource: 'reward',
    onMutationSuccess: () => {
      messageApi.success('생성이 완료되었습니다.');
    },
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
  });

  // 원본 onFinish 함수를 저장
  const originalOnFinish = formProps.onFinish;

  // 커스텀 onFinish 함수 정의
  const customOnFinish = async (values: any) => {
    const data = { ...values };
    
    // 이미지 데이터 처리
    if (data.thumbnail && Array.isArray(data.thumbnail)) {
      if (data.thumbnail.length > 0 && data.thumbnail[0].response?.path) {
        data.thumbnail = data.thumbnail[0].response.path;
      } else {
        data.thumbnail = null;
      }
    }
    
    ['overview_images', 'location_images', 'size_guide_images'].forEach(field => {
      if (data[field] && Array.isArray(data[field])) {
        data[field] = data[field]
          .map((item: any) => {
            if (item.response?.path) {
              return item.response.path;
            }
            return null;
          })
          .filter(Boolean);
      }
    });
    
    // size_guide 데이터 처리 - 문자열인 경우 JSON으로 파싱
    if (data.size_guide) {
      Object.keys(data.size_guide).forEach(locale => {
        if (typeof data.size_guide[locale] === 'string') {
          if (data.size_guide[locale].trim().startsWith('[') || data.size_guide[locale].trim().startsWith('{')) {
            try {
              data.size_guide[locale] = JSON.parse(data.size_guide[locale]);
            } catch (e) {
              console.error(`사이즈 가이드 데이터 파싱 오류 (${locale}):`, e);
            }
          }
        }
      });
    }
    
    // 원본 onFinish 함수 호출
    return originalOnFinish?.(data);
  };

  // onFinish 함수 교체
  const modifiedFormProps = {
    ...formProps,
    onFinish: customOnFinish,
  };

  return (
    <Create
      breadcrumb={false}
      title={resourceInfo?.meta?.create?.label}
      saveButtonProps={saveButtonProps}
    >
      {contextHolder}
      <RewardForm
        mode="create"
        formProps={modifiedFormProps}
        saveButtonProps={saveButtonProps}
      />
    </Create>
  );
} 