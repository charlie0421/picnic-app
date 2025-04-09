'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, DatePicker, message } from 'antd';
import { useState } from 'react';
import { useCreate, useNavigation, useResource } from '@refinedev/core';
import ImageUpload from '@/components/features/upload';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import MultiLanguageInput from '@/components/ui/MultiLanguageInput';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

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

        dataToSave = {
          ...dataToSave,
          debut_date: dateStr,
          debut_yy: year,
          debut_mm: month,
          debut_dd: day,
        };
      }

      // 직접 API 호출
      createArtistGroup(
        {
          resource: 'artist_group',
          values: dataToSave,
        },
        {
          onSuccess: (data) => {
            messageApi.success('아티스트 그룹이 성공적으로 생성되었습니다');
            list('artist-group');
          },
          onError: (error) => {
            messageApi.error(`생성 실패: ${error}`);
          },
        },
      );
    } catch (error) {
      messageApi.error(`오류 발생: ${error}`);
    }
  };

  const { resource } = useResource();

  return (
    <AuthorizePage resource='artist_group' action='create'>
      <Create
        breadcrumb={false}
        
        title={resource?.meta?.create?.label}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: handleSave,
        }}
      >
        {contextHolder}
        <Form
          {...formProps}
          layout='vertical'
          onValuesChange={handleFormChange}
        >
          <MultiLanguageInput name='name' label='이름' required={true} />

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
    </AuthorizePage>
  );
}
