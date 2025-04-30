'use client';

import { Form, Input, DatePicker, message } from 'antd';
import { useForm } from '@refinedev/antd';
import { ArtistGroup } from '@/lib/types/artist';
import { useState, useEffect } from 'react';
import { useCreate, useUpdate, useNavigation } from '@refinedev/core';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import ImageUpload from '@/components/features/upload';
import MultiLanguageInput from '@/components/ui/MultiLanguageInput';

// UTC 플러그인 확장
dayjs.extend(utc);

type ArtistGroupFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<ArtistGroup>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<ArtistGroup>>['saveButtonProps'];
  onFinish?: (values: ArtistGroup) => Promise<any>;
};

interface FormValues {
  name: Record<string, string>;
  debut_date?: any;
  image?: string;
}

export default function ArtistGroupForm({
  mode,
  id,
  formProps,
  saveButtonProps,
  onFinish,
}: ArtistGroupFormProps) {
  const [formData, setFormData] = useState<any>(null);
  const [messageApi, contextHolder] = message.useMessage();
  const { list } = useNavigation();
  const { mutate: createArtistGroup } = useCreate();
  const { mutate: updateArtistGroup } = useUpdate();

  // 폼 데이터 변경 핸들러
  const handleFormChange = (changedValues: any, allValues: any) => {
    setFormData(allValues);
  };

  // 폼 초기 데이터 설정
  useEffect(() => {
    if (formProps.initialValues) {
      setFormData(formProps.initialValues);
    }
  }, [formProps.initialValues]);

  // 저장 핸들러
  const handleSave = async () => {
    try {
      // 폼 검증
      const values = (await formProps.form?.validateFields()) as FormValues;
      if (!values) return;

      // 날짜 변환 처리
      let dataToSave: any = { ...values };
      console.log('Original values:', values); // 디버깅용 로그

      if (values.debut_date) {
        // 날짜를 직접 파싱
        const dateStr =
          typeof values.debut_date === 'string'
            ? values.debut_date
            : values.debut_date.format('YYYY-MM-DD');
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

        console.log('Date transformation:', {
          original: values.debut_date,
          parsed: {
            dateStr,
            year,
            month,
            day,
          },
          final: {
            debut_date: dateStr,
            debut_yy: year,
            debut_mm: month,
            debut_dd: day,
          },
        });
      }

      console.log('Final data to save:', dataToSave);

      if (mode === 'create') {
        // 직접 API 호출 - 생성
        await createArtistGroup(
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
      } else if (mode === 'edit' && id) {
        // 직접 API 호출 - 수정
        await updateArtistGroup(
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
      }
    } catch (error) {
      console.error('Save error:', error); // 디버깅용 로그
      messageApi.error(`오류 발생: ${error}`);
    }
  };

  // saveButtonProps의 onClick 핸들러를 제거하고 Form의 onFinish를 사용
  const modifiedSaveButtonProps = {
    ...saveButtonProps,
    onClick: undefined,
  };

  return (
    <>
      {contextHolder}
      <Form
        {...formProps}
        layout='vertical'
        onValuesChange={handleFormChange}
        onFinish={handleSave}
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
              return date.format('YYYY-MM-DD');
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
    </>
  );
}
