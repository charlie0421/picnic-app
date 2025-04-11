'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, DatePicker, Select, message } from 'antd';
import dayjs from 'dayjs';
import { useEffect, useState } from 'react';
import { useOne, useResource } from '@refinedev/core';
import ImageUpload from '@/components/features/upload';
import { supabaseBrowserClient } from '@/lib/supabase/client';
import { getCdnImageUrl } from '@/lib/image';
import { MultiLanguageInput } from '@/components/ui';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

export default function ArtistEdit() {
  const [groups, setGroups] = useState<any[]>([]);
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  // 아티스트 그룹 정보 가져오기
  useEffect(() => {
    const fetchGroups = async () => {
      try {
        const { data, error } = await supabaseBrowserClient
          .from('artist_group')
          .select('id, name, image')
          .order('id', { ascending: false });

        if (error) {
          console.error('Error fetching artist groups:', error);
          setGroups([]);
        } else {
          setGroups(data || []);
        }
      } catch (error) {
        console.error('Error fetching artist groups:', error);
        setGroups([]);
      }
    };

    fetchGroups();
  }, []);

  const { formProps, saveButtonProps } = useForm({
    resource: 'artist',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('아티스트가 성공적으로 수정되었습니다');
    },
  });

  // 그룹명 필터링 함수
  const filterGroupOption = (input: string, option: any) => {
    if (!option) return false;

    const name = option.name || {};
    const searchText = input.toLowerCase();

    return (
      (name.ko?.toLowerCase() || '').includes(searchText) ||
      (name.en?.toLowerCase() || '').includes(searchText) ||
      (name.ja?.toLowerCase() || '').includes(searchText) ||
      (name.zh?.toLowerCase() || '').includes(searchText)
    );
  };

  // 저장 버튼 클릭 핸들러
  const handleSave = async (values: any) => {
    // 날짜 변환 처리 로직
    let updatedValues = { ...values };

    // 생년월일 처리
    if (values.birth_date) {
      const dateStr =
        typeof values.birth_date === 'string'
          ? values.birth_date
          : values.birth_date.format('YYYY-MM-DD');
      const date = dayjs(dateStr);

      const year = Number(date.format('YYYY'));
      const month = Number(date.format('MM'));
      const day = Number(date.format('DD'));

      updatedValues = {
        ...updatedValues,
        birth_date: dateStr,
        yy: year,
        mm: month,
        dd: day,
      };
    }

    // 데뷔일 처리
    if (values.debut_date) {
      const dateStr =
        typeof values.debut_date === 'string'
          ? values.debut_date
          : values.debut_date.format('YYYY-MM-DD');
      const date = dayjs(dateStr);

      const year = Number(date.format('YYYY'));
      const month = Number(date.format('MM'));
      const day = Number(date.format('DD'));

      updatedValues = {
        ...updatedValues,
        debut_date: dateStr,
        debut_yy: year,
        debut_mm: month,
        debut_dd: day,
      };
    }

    return updatedValues;
  };

  return (
    <AuthorizePage resource='artist' action='edit'>
      <Edit
        breadcrumb={false}
        title={resource?.meta?.edit?.label}
        saveButtonProps={{
          ...saveButtonProps,
          onClick: async () => {
            const values = await formProps.form?.validateFields();
            if (values) {
              const transformedValues = await handleSave(values);
              formProps.onFinish?.(transformedValues);
            }
          },
        }}
      >
        {contextHolder}
        <Form {...formProps} layout='vertical'>
          <Form.Item label='ID' name='id'>
            <Input disabled />
          </Form.Item>

          <MultiLanguageInput name='name' label='이름' required={true} />

          <Form.Item
            label='아티스트 그룹'
            name='group_id'
            rules={[
              {
                required: true,
                message: '아티스트 그룹을 선택해주세요',
              },
            ]}
          >
            <Select
              placeholder='아티스트 그룹 선택'
              showSearch
              filterOption={filterGroupOption}
              options={groups.map((group) => ({
                label: group.name?.ko || group.name?.en || 'N/A',
                value: group.id,
                name: group.name,
              }))}
            />
          </Form.Item>

          <Form.Item
            label='생년월일'
            name='birth_date'
            getValueProps={(value) => ({
              value: value ? dayjs(value) : undefined,
            })}
          >
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label='데뷔일'
            name='debut_date'
            getValueProps={(value) => ({
              value: value ? dayjs(value) : undefined,
            })}
          >
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label='이미지'
            name='image'
            rules={[
              {
                required: true,
                message: '이미지를 업로드해주세요',
              },
            ]}
            getValueProps={(value) => ({
              value: value ? getCdnImageUrl(value) : undefined,
            })}
          >
            <ImageUpload />
          </Form.Item>
        </Form>
      </Edit>
    </AuthorizePage>
  );
}
