'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Select, message, DatePicker } from 'antd';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useUpdate, useNavigation, useResource } from '@refinedev/core';
import ImageUpload from '@/components/features/upload';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

dayjs.extend(utc);

export default function ArtistGroupEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const [formData, setFormData] = useState<any>(null);
  const { list } = useNavigation();

  const { mutate: updateArtistGroup } = useUpdate();

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'artist_group',
    id: id,
    meta: {
      select: '*',
    },
    action: 'edit',
  });

  // 폼 데이터 변경 핸들러
  const handleFormChange = (changedValues: any, allValues: any) => {
    setFormData(allValues);
  };

  // 폼 초기 데이터 설정
  useEffect(() => {
    if (queryResult?.data?.data) {
      setFormData(queryResult.data.data);
    }
  }, [queryResult?.data?.data]);

  // 저장 핸들러
  const handleSave = async () => {
    if (!formData) return;

    try {
      // 날짜 변환 처리
      let dataToSave = { ...formData };

      if (formData.debut_date) {
        // 날짜를 직접 파싱
        const dateStr =
          typeof formData.debut_date === 'string'
            ? formData.debut_date
            : formData.debut_date.format('YYYY-MM-DD');
        const date = dayjs(dateStr);

        // 명시적으로 numeric 타입으로 변환
        const year = Number(date.format('YYYY'));
        const month = Number(date.format('MM'));
        const day = Number(date.format('DD'));

        dataToSave = {
          ...dataToSave,
          debut_date: dateStr,
          debut_yy: year,
          debut_mm: month,
          debut_dd: day,
        };
      }

      // 직접 API 호출
      updateArtistGroup(
        {
          resource: 'artist_group',
          id: id,
          values: dataToSave,
        },
        {
          onSuccess: (data) => {
            messageApi.success('아티스트 그룹이 성공적으로 수정되었습니다');
            list('artist-group');
          },
          onError: (error) => {
            messageApi.error(`수정 실패: ${error}`);
          },
        },
      );
    } catch (error) {
      messageApi.error(`오류 발생: ${error}`);
    }
  };

  const { resource } = useResource();
  return (
    <Edit
      breadcrumb={false}
      goBack={false}
      title={resource?.meta?.edit?.label}
      saveButtonProps={{
        ...saveButtonProps,
        onClick: handleSave,
      }}
    >
      {contextHolder}
      <Form {...formProps} layout='vertical' onValuesChange={handleFormChange}>
        <Form.Item
          label='이름 (한국어) 🇰🇷'
          name={['name', 'ko']}
          rules={[
            {
              required: true,
              message: '한국어 이름을 입력해주세요.',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label='이름 (영어) 🇺🇸'
          name={['name', 'en']}
          rules={[
            {
              required: true,
              message: '영어 이름을 입력해주세요.',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label='이름 (일본어) 🇯🇵'
          name={['name', 'ja']}
          rules={[
            {
              required: true,
              message: '일본어 이름을 입력해주세요.',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label='이름 (중국어) 🇨🇳'
          name={['name', 'zh']}
          rules={[
            {
              required: true,
              message: '중국어 이름을 입력해주세요.',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label='데뷔일'
          name='debut_date'
          rules={[
            {
              required: true,
              message: '데뷔일을 선택해주세요.',
            },
          ]}
          getValueFromEvent={(date) => {
            if (date) {
              return date.utc(true);
            }
            return undefined;
          }}
          getValueProps={(value) => {
            if (value) {
              return {
                value: dayjs(value),
              };
            }
            return { value: undefined };
          }}
        >
          <DatePicker style={{ width: '100%' }} />
        </Form.Item>

        <Form.Item
          label='그룹 이미지'
          name='image'
          valuePropName='value'
          getValueFromEvent={(e) => {
            if (typeof e === 'string') {
              return e;
            }
            if (e && e.file && e.file.response) {
              return e.file.response;
            }
            return e;
          }}
        >
          <ImageUpload folder='artist-group' />
        </Form.Item>
      </Form>
    </Edit>
  );
}
