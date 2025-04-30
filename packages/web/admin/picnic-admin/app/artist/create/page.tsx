'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, Select, DatePicker, message } from 'antd';
import { useState, useEffect } from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import ImageUpload from '@/components/features/upload';
import { supabaseBrowserClient } from '@/lib/supabase/client';
import { MultiLanguageInput } from '@/components/ui';
import { useResource } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';

// UTC 플러그인 확장
dayjs.extend(utc);

export default function ArtistCreate() {
  const [groups, setGroups] = useState<any[]>([]);
  const [loadingGroups, setLoadingGroups] = useState<boolean>(true);
  const [messageApi, contextHolder] = message.useMessage();
  const { resource } = useResource();

  // 아티스트 그룹 정보 직접 Supabase에서 가져오기
  useEffect(() => {
    const fetchGroups = async () => {
      setLoadingGroups(true);
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
      } finally {
        setLoadingGroups(false);
      }
    };

    fetchGroups();
  }, []);

  const { formProps, saveButtonProps } = useForm({
    resource: 'artist',
    warnWhenUnsavedChanges: true,
    redirect: 'list',
    onMutationSuccess: () => {
      messageApi.success('아티스트가 성공적으로 생성되었습니다');
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
    // 디버깅을 위한 로그
    console.log('Form values:', values);
    console.log('Debut date value:', values.debut_date);

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
    } else {
      // 데뷔일이 없는 경우 관련 필드들을 명시적으로 null로 설정
      updatedValues = {
        ...updatedValues,
        debut_date: null,
        debut_yy: null,
        debut_mm: null,
        debut_dd: null,
      };
    }

    // 변환된 값 로깅
    console.log('Transformed values:', updatedValues);

    return updatedValues;
  };

  return (
    <AuthorizePage action='create'>
      <Create
        breadcrumb={false}
        title={resource?.meta?.create?.label}
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
              loading={loadingGroups}
              showSearch
              placeholder='아티스트 그룹 선택'
              options={groups.map((group) => ({
                label: group.name?.ko || group.name?.en || 'N/A',
                value: group.id,
                name: group.name,
              }))}
              filterOption={filterGroupOption}
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

          <Form.Item
            label='이미지'
            name='image'
            rules={[
              {
                required: true,
                message: '이미지를 업로드해주세요',
              },
            ]}
          >
            <ImageUpload />
          </Form.Item>
        </Form>
      </Create>
    </AuthorizePage>
  );
}
