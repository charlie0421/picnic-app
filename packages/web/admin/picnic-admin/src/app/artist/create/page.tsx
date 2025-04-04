'use client';

import { Create, useForm } from '@refinedev/antd';
import { Form, InputNumber, Select, DatePicker } from 'antd';
import { useState, useEffect } from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import { useCreate, useMany, useNavigation } from '@refinedev/core';
import ImageUpload from '@/components/upload';
import { supabaseBrowserClient } from '@utils/supabase/client';
import { getImageUrl } from '@utils/image';
import MultiLanguageInput from '@/components/common/MultiLanguageInput';

dayjs.extend(utc);

export default function ArtistCreate() {
  const [formData, setFormData] = useState<any>({});
  const [groups, setGroups] = useState<any[]>([]);
  const [loadingGroups, setLoadingGroups] = useState<boolean>(true);
  const { mutate: createArtist } = useCreate();
  const { list } = useNavigation();

  const { formProps, saveButtonProps } = useForm({
    resource: 'artist',
  });

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
          console.log('Loaded groups:', data);
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

  // 폼 데이터 변경 핸들러
  const handleFormChange = (changedValues: any, allValues: any) => {
    setFormData(allValues);
  };

  // 저장 핸들러
  const handleSave = async () => {
    try {
      // 날짜 변환 처리
      let dataToSave = { ...formData };

      // 생년월일 처리
      if (formData.birth_date) {
        // 날짜를 직접 파싱
        const dateStr =
          typeof formData.birth_date === 'string'
            ? formData.birth_date
            : formData.birth_date.format('YYYY-MM-DD');
        const date = dayjs(dateStr);

        // 명시적으로 numeric 타입으로 변환
        const year = Number(date.format('YYYY'));
        const month = Number(date.format('MM'));
        const day = Number(date.format('DD'));

        console.log('Parsed birth date values:', { year, month, day, dateStr });

        dataToSave = {
          ...dataToSave,
          birth_date: dateStr,
          yy: year,
          mm: month,
          dd: day,
        };
      }

      // 데뷔일 처리
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

        console.log('Parsed debut date values:', { year, month, day, dateStr });

        dataToSave = {
          ...dataToSave,
          debut_date: dateStr,
          debut_yy: year,
          debut_mm: month,
          debut_dd: day,
        };
      }

      console.log('Creating artist with data:', dataToSave);

      // 직접 API 호출
      createArtist(
        {
          resource: 'artist',
          values: dataToSave,
        },
        {
          onSuccess: (data) => {
            console.log('Create success:', data);
            // window.history.back() 대신 RefineJS의 list 함수 사용
            list('artist');
          },
          onError: (error) => {
            console.error('Create error:', error);
          },
        },
      );
    } catch (error) {
      console.error('Error creating artist:', error);
    }
  };

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

  return (
    <Create
      saveButtonProps={{
        ...saveButtonProps,
        onClick: handleSave,
      }}
    >
      <Form {...formProps} layout='vertical' onValuesChange={handleFormChange}>
        <MultiLanguageInput name='name' label='이름' required={true} />

        <Form.Item
          label={'그룹'}
          name={'group_id'}
          rules={[
            {
              required: true,
              message: '그룹을 선택해주세요',
            },
          ]}
        >
          <Select
            loading={loadingGroups}
            showSearch
            placeholder='그룹을 검색하세요'
            options={groups.map((group) => ({
              label: (
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '10px' }}
                >
                  {group.image ? (
                    <img
                      src={getImageUrl(group.image)}
                      alt='그룹 이미지'
                      style={{
                        width: '24px',
                        height: '24px',
                        objectFit: 'cover',
                        borderRadius: '4px',
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: '24px',
                        height: '24px',
                        backgroundColor: '#f0f0f0',
                        borderRadius: '4px',
                      }}
                    />
                  )}
                  <span>{group.name?.ko || '이름 없음'}</span>
                </div>
              ),
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
        >
          <DatePicker style={{ width: '100%' }} />
        </Form.Item>

        <Form.Item
          label='데뷔일'
          name='debut_date'
          rules={[
            {
              required: true,
              message: '데뷔일을 선택해주세요',
            },
          ]}
        >
          <DatePicker style={{ width: '100%' }} />
        </Form.Item>

        <Form.Item
          label='아티스트 이미지'
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
          <ImageUpload folder='artist' />
        </Form.Item>
      </Form>
    </Create>
  );
}
