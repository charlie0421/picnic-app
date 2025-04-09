'use client';

import { Form, Input, DatePicker, InputNumber, Select } from 'antd';
import { Banner } from '@/lib/types/banner';
import dayjs from '@/lib/dayjs';
import ImageUpload from '@/components/features/upload';
import { getCdnImageUrl } from '@/lib/image';
import { useCreate } from '@refinedev/core';
import { useForm } from '@refinedev/antd';
import { BANNER_LOCATIONS } from '@/lib/banner';

type BannerFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<Banner>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<Banner>>['saveButtonProps'];
  onFinish?: (values: Banner) => Promise<any>;
  redirectPath?: string;
};

export default function BannerForm({
  mode,
  formProps,
  saveButtonProps,
  onFinish,
  redirectPath,
}: BannerFormProps) {
  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={{
        ...formProps.initialValues,
        image: {
          ko: formProps.initialValues?.image?.ko,
          en: formProps.initialValues?.image?.en,
          ja: formProps.initialValues?.image?.ja,
          zh: formProps.initialValues?.image?.zh,
        },
        start_at: formProps.initialValues?.start_at,
        end_at: formProps.initialValues?.end_at,
        order: formProps.initialValues?.order,
        duration: formProps.initialValues?.duration,
        link: formProps.initialValues?.link,
      }}
    >
      <Form.Item
        name={['image', 'ko']}
        label='이미지(한국어)'
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
        rules={[{ required: true, message: '이미지를 업로드해주세요' }]}
      >
        <ImageUpload folder='banner' />
      </Form.Item>
      <Form.Item
        label='이미지(영어)'
        name={['image', 'en']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
        rules={[{ required: true, message: '이미지를 업로드해주세요' }]}
      >
        <ImageUpload folder='banner' />
      </Form.Item>
      <Form.Item
        label='이미지(일본어)'
        name={['image', 'ja']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
        rules={[{ required: true, message: '이미지를 업로드해주세요' }]}
      >
        <ImageUpload folder='banner' />
      </Form.Item>
      <Form.Item
        label='이미지(중국어)'
        name={['image', 'zh']}
        getValueProps={(value) => ({
          value: value ? getCdnImageUrl(value) : undefined,
        })}
        rules={[{ required: true, message: '이미지를 업로드해주세요' }]}
      >
        <ImageUpload folder='banner' />
      </Form.Item>
      <Form.Item
        label='시작일'
        name='start_at'
        rules={[
          {
            required: true,
            message: '시작일을 선택해주세요',
          },
        ]}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker showTime />
      </Form.Item>
      <Form.Item
        label='종료일'
        name='end_at'
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker showTime />
      </Form.Item>
      <Form.Item
        label='위치'
        name='location'
        rules={[{ required: true, message: '위치를 선택해주세요' }]}
      >
        <Select options={BANNER_LOCATIONS} />
      </Form.Item>
      <Form.Item label='순서' name='order'>
        <InputNumber />
      </Form.Item>
      <Form.Item label='지속시간' name='duration'>
        <InputNumber />
      </Form.Item>
      <Form.Item label='링크' name='link'>
        <Input />
      </Form.Item>
    </Form>
  );
}
