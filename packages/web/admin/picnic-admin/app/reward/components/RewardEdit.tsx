'use client';

import { Edit, useForm } from '@refinedev/antd';
import { message } from 'antd';
import RewardForm from './RewardForm';
import { useResource, useOne } from '@refinedev/core';
import { Reward } from './types';
import { useState, useEffect } from 'react';
import { getCdnImageUrl } from '@/lib/image';

interface RewardEditProps {
  id: string;
  resource?: string;
}

export default function RewardEdit({ id, resource }: RewardEditProps) {
  const [messageApi, contextHolder] = message.useMessage();
  const { resource: resourceInfo } = useResource();
  const [formData, setFormData] = useState<Reward | undefined>(undefined);

  // 데이터 직접 조회
  const { data: rewardData, isLoading } = useOne<Reward>({
    resource: resource || 'reward',
    id,
  });

  useEffect(() => {
    // 데이터가 로드되면 콘솔에 출력
    if (rewardData?.data) {
      console.log('데이터베이스에서 가져온 원본 데이터:', rewardData.data);
      
      // 기본값 처리
      const processedData = { ...rewardData.data };
      
      // 필수 필드가 없는 경우 초기화
      if (!processedData.title) processedData.title = {};
      if (!processedData.location) processedData.location = {};
      if (!processedData.size_guide) processedData.size_guide = {};
      
      // 순서가 null이면 0으로 설정
      if (processedData.order === null || processedData.order === undefined) {
        processedData.order = 0;
      }
      
      setFormData(processedData);
    }
  }, [rewardData]);

  const { formProps, saveButtonProps, queryResult } = useForm<Reward>({
    resource: resource || 'reward',
    id,
    onMutationSuccess: () => {
      messageApi.success('수정이 완료되었습니다.');
    },
    errorNotification: (error) => {
      return {
        message: '오류가 발생했습니다.',
        description: error?.message || '알 수 없는 오류가 발생했습니다.',
        type: 'error',
      };
    },
    queryOptions: {
      enabled: true,
      retry: 3,
      onSuccess: (data) => {
        console.log('useForm에서 가져온 데이터:', data);
      },
      onError: (error) => {
        console.error('데이터 조회 오류:', error);
      }
    }
  });

  // 원본 onFinish 함수를 저장
  const originalOnFinish = formProps.onFinish;

  // 커스텀 onFinish 함수 정의
  const customOnFinish = async (values: any) => {
    console.log('폼 제출 값:', values);
    const data = { ...values };
    
    // 이미지 데이터 처리
    if (data.thumbnail && Array.isArray(data.thumbnail)) {
      if (data.thumbnail.length > 0 && data.thumbnail[0].response?.path) {
        data.thumbnail = data.thumbnail[0].response.path;
      } else if (data.thumbnail.length > 0 && data.thumbnail[0].url) {
        // 이미 업로드된 이미지 URL에서 CDN 부분 제거
        const url = data.thumbnail[0].url;
        data.thumbnail = url.split('?')[0]; // CDN 매개변수 제거
      } else {
        data.thumbnail = null;
      }
    } else if (data.thumbnail === null || data.thumbnail === undefined) {
      data.thumbnail = null;
    }
    
    ['overview_images', 'location_images', 'size_guide_images'].forEach(field => {
      if (data[field] && Array.isArray(data[field])) {
        data[field] = data[field]
          .map((item: any) => {
            if (item.response?.path) {
              return item.response.path;
            } else if (item.url) {
              return item.url.split('?')[0]; // CDN 매개변수 제거
            }
            return null;
          })
          .filter(Boolean);
      } else {
        // 배열이 아닌 경우 빈 배열로 초기화
        data[field] = [];
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
    
    console.log('서버에 전송될 데이터:', data);
    
    // 원본 onFinish 함수 호출
    return originalOnFinish?.(data);
  };

  // onFinish 함수 교체
  const modifiedFormProps = {
    ...formProps,
    onFinish: customOnFinish,
    // 직접 조회한 데이터가 있으면 그것을 사용
    initialValues: formData || formProps.initialValues,
  };

  console.log('최종 initialValues:', modifiedFormProps.initialValues);

  return (
    <Edit
      breadcrumb={false}
      title={resourceInfo?.meta?.edit?.label}
      saveButtonProps={saveButtonProps}
      isLoading={isLoading}
    >
      {contextHolder}
      <RewardForm
        mode="edit"
        formProps={modifiedFormProps}
        saveButtonProps={saveButtonProps}
      />
    </Edit>
  );
} 