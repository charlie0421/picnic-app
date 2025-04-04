'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, Input, DatePicker, message } from 'antd';
import { useState } from 'react';
import { useCreate, useNavigation } from '@refinedev/core';
import ImageUpload from '@/components/upload';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

dayjs.extend(utc);

export default function ArtistGroupCreate() {
  const [messageApi, contextHolder] = message.useMessage();
  const [formData, setFormData] = useState<any>({});
  const { list } = useNavigation();

  const { mutate: createArtistGroup } = useCreate();
  const { formProps, saveButtonProps } = useForm({
    resource: 'artist_group',
  });

  // 폼 데이터 변경 핸들러
  const handleFormChange = (changedValues: any, allValues: any) => {
    setFormData(allValues);
  };

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

        console.log('Parsed date values (create):', {
          year,
          month,
          day,
          dateStr,
        });

        dataToSave = {
          ...dataToSave,
          debut_date: dateStr,
          debut_yy: year,
          debut_mm: month,
          debut_dd: day,
        };
      }

      console.log('Creating artist group with data:', dataToSave);

      // 직접 API 호출
      createArtistGroup(
        {
          resource: 'artist_group',
          values: dataToSave,
        },
        {
          onSuccess: (data) => {
            console.log('Create success:', data);
            messageApi.success('아티스트 그룹이 성공적으로 생성되었습니다');
            list('artist-group');
          },
          onError: (error) => {
            console.error('Create error:', error);
            messageApi.error(`생성 실패: ${error}`);
          },
        },
      );
    } catch (error) {
      console.error('Error creating artist group:', error);
      messageApi.error(`오류 발생: ${error}`);
    }
  };

  return (
    <Create
      title='아티스트 그룹 생성'
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
    </Create>
  );
}
