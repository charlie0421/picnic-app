import { Form, Select, DatePicker, Divider, Space, Typography } from 'antd';
import { MultiLanguageInput } from '@/components/ui';
import ImageUpload from '@/components/features/upload';
import { useEffect, useState } from 'react';
import { supabaseBrowserClient } from '@/lib/supabase/client';
import dayjs from 'dayjs';

const { Title } = Typography;

interface ArtistFormProps {
  form: any;
  loadingGroups?: boolean;
  groups: any[];
  filterGroupOption: (input: string, option: any) => boolean;
}

export default function ArtistForm({
  form,
  loadingGroups,
  groups,
  filterGroupOption,
}: ArtistFormProps) {
  return (
    <>
      <MultiLanguageInput
        name='name'
        label='이름'
        required={true}
        requiredLanguages={['ko', 'en']}
      />

      <Form.Item label='아티스트 그룹' name='group_id'>
        <Select
          loading={loadingGroups}
          showSearch
          placeholder='아티스트 그룹 선택'
          options={groups.map((group) => ({
            label: group.name?.ko || group.name?.en || 'N/A',
            value: group.id,
            name: group.name,
          }))}
          filterOption={filterGroupOption}
          allowClear
        />
      </Form.Item>

      <Form.Item
        label='성별'
        name='gender'
        rules={[
          {
            required: true,
            message: '성별을 선택해주세요',
          },
        ]}
      >
        <Select
          placeholder='성별을 선택하세요'
          options={[
            { label: '남성', value: 'male' },
            { label: '여성', value: 'female' },
            { label: '기타', value: 'other' },
          ]}
        />
      </Form.Item>

      <Form.Item
        label='생년월일'
        name='birth_date'
        rules={[
          {
            required: true,
            message: '생년월일을 선택해주세요',
          },
        ]}
        getValueFromEvent={(date) => {
          if (date) {
            return date.format('YYYY-MM-DD');
          }
          return undefined;
        }}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker style={{ width: '100%' }} />
      </Form.Item>

      <Form.Item
        label='데뷔일'
        name='debut_date'
        getValueFromEvent={(date) => {
          if (date) {
            return date.format('YYYY-MM-DD');
          }
          return undefined;
        }}
        getValueProps={(value) => ({
          value: value ? dayjs(value) : undefined,
        })}
      >
        <DatePicker style={{ width: '100%' }} />
      </Form.Item>

      <Form.Item label='이미지' name='image'>
        <ImageUpload />
      </Form.Item>

      <Divider>
        <Title level={5}>아티스트 정보</Title>
      </Divider>

      <Space direction='vertical' style={{ width: '100%' }}>
        <Form.Item
          label='솔로'
          name='is_solo'
          valuePropName='checked'
          getValueProps={(value) => ({
            value: value === true,
          })}
        >
          <Select
            placeholder='솔로 여부를 선택하세요'
            options={[
              { label: '예', value: true },
              { label: '아니오', value: false },
            ]}
          />
        </Form.Item>

        <Form.Item
          label='K-POP'
          name='is_kpop'
          valuePropName='checked'
          getValueProps={(value) => ({
            value: value === true,
          })}
        >
          <Select
            placeholder='K-POP 여부를 선택하세요'
            options={[
              { label: '예', value: true },
              { label: '아니오', value: false },
            ]}
          />
        </Form.Item>

        <Form.Item
          label='뮤지컬'
          name='is_musical'
          valuePropName='checked'
          getValueProps={(value) => ({
            value: value === true,
          })}
        >
          <Select
            placeholder='뮤지컬 여부를 선택하세요'
            options={[
              { label: '예', value: true },
              { label: '아니오', value: false },
            ]}
          />
        </Form.Item>
      </Space>
    </>
  );
}
