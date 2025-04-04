'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, DatePicker, Select, message } from 'antd';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import { useState, useEffect, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useUpdate, useMany, useNavigation } from '@refinedev/core';
import ImageUpload from '@/components/upload';
import { supabaseBrowserClient } from '@utils/supabase/client';
import { getImageUrl } from '@utils/image';

dayjs.extend(utc);

export default function ArtistEdit() {
  const params = useParams();
  const id = params.id as string;
  const [messageApi, contextHolder] = message.useMessage();
  const [formData, setFormData] = useState<any>(null);
  const [initialDataLoaded, setInitialDataLoaded] = useState<boolean>(false);
  const [groups, setGroups] = useState<any[]>([]);
  const { list } = useNavigation();

  const { mutate: updateArtist } = useUpdate();

  const { formProps, saveButtonProps, queryResult } = useForm({
    resource: 'artist',
    id: id,
    meta: {
      select: '*',
    },
    action: 'edit',
  });

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
          console.log('Loaded groups:', data);
          setGroups(data || []);
        }
      } catch (error) {
        console.error('Error fetching artist groups:', error);
        setGroups([]);
      }
    };

    fetchGroups();
  }, []);

  // 폼 데이터 변경 핸들러
  const handleFormChange = (changedValues: any, allValues: any) => {
    setFormData(allValues);
  };

  // 폼 초기 데이터 설정
  useEffect(() => {
    if (queryResult?.data?.data) {
      console.log('Artist Edit - Initial Data Loaded:', queryResult.data.data);
      setFormData(queryResult.data.data);
      setInitialDataLoaded(true);
    }
  }, [queryResult?.data?.data]);

  // 생년월일 값 계산
  const birthDate = useMemo(() => {
    if (queryResult?.data?.data?.birth_date) {
      return dayjs(queryResult.data.data.birth_date);
    }
    return undefined;
  }, [queryResult?.data?.data?.birth_date]);

  // 데뷔일 값 계산
  const debutDate = useMemo(() => {
    const data = queryResult?.data?.data;
    if (data?.debut_date) {
      return dayjs(data.debut_date);
    } else if (data?.debut_yy) {
      const month = data.debut_mm ? data.debut_mm - 1 : 0;
      const day = data.debut_dd || 1;
      return dayjs(`${data.debut_yy}-${month + 1}-${day}`);
    }
    return undefined;
  }, [queryResult?.data?.data]);

  // 저장 핸들러
  const handleSave = async () => {
    if (!formData) return;

    try {
      // 날짜 변환 처리
      let updatedData = { ...formData };

      // 생년월일 처리
      if (formData.birth_date) {
        const dateStr =
          typeof formData.birth_date === 'string'
            ? formData.birth_date
            : formData.birth_date.format('YYYY-MM-DD');
        const date = dayjs(dateStr);

        const year = Number(date.format('YYYY'));
        const month = Number(date.format('MM'));
        const day = Number(date.format('DD'));

        console.log('Parsed birth date values:', { year, month, day, dateStr });

        updatedData = {
          ...updatedData,
          birth_date: dateStr,
          yy: year,
          mm: month,
          dd: day,
        };
      }

      // 데뷔일 처리
      if (formData.debut_date) {
        const dateStr =
          typeof formData.debut_date === 'string'
            ? formData.debut_date
            : formData.debut_date.format('YYYY-MM-DD');
        const date = dayjs(dateStr);

        const year = Number(date.format('YYYY'));
        const month = Number(date.format('MM'));
        const day = Number(date.format('DD'));

        console.log('Parsed debut date values:', { year, month, day, dateStr });

        updatedData = {
          ...updatedData,
          debut_date: dateStr,
          debut_yy: year,
          debut_mm: month,
          debut_dd: day,
        };
      }

      console.log('Updating artist with data:', updatedData);

      // 직접 API 호출
      updateArtist(
        {
          resource: 'artist',
          id: id,
          values: updatedData,
        },
        {
          onSuccess: (data) => {
            console.log('Update success:', data);
            messageApi.success('아티스트가 성공적으로 수정되었습니다');
            // window.history.back() 대신 RefineJS의 list 함수 사용
            list('artist');
          },
          onError: (error) => {
            console.error('Update error:', error);
            messageApi.error(`수정 실패: ${error}`);
          },
        },
      );
    } catch (error) {
      console.error('Error updating artist:', error);
      messageApi.error(`오류 발생: ${error}`);
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
    <Edit
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
        initialValues={formData || queryResult?.data?.data}
      >
        <Form.Item label={'ID'} name='id'>
          <Input disabled />
        </Form.Item>

        <Form.Item
          label={'이름 (한국어)'}
          name={['name', 'ko']}
          rules={[
            {
              required: true,
              message: '한국어 이름을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label={'이름 (영어)'}
          name={['name', 'en']}
          rules={[
            {
              required: true,
              message: '영어 이름을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label={'이름 (일본어)'}
          name={['name', 'ja']}
          rules={[
            {
              required: true,
              message: '일본어 이름을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>

        <Form.Item
          label={'이름 (중국어)'}
          name={['name', 'zh']}
          rules={[
            {
              required: true,
              message: '중국어 이름을 입력해주세요',
            },
          ]}
        >
          <Input />
        </Form.Item>

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
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    />
                  )}
                  <span>{`${group.name?.ko || '이름 없음'} / ${
                    group.name?.en || ''
                  } / ${group.name?.ja || ''} / ${group.name?.zh || ''}`}</span>
                </div>
              ),
              value: group.id,
              name: group.name,
            }))}
            filterOption={(input, option) => filterGroupOption(input, option)}
            optionFilterProp='children'
          />
        </Form.Item>

        <Form.Item
          label={'성별'}
          name={'gender'}
          rules={[
            {
              required: true,
              message: '성별을 선택해주세요',
            },
          ]}
        >
          <Select
            options={[
              { value: 'MALE', label: '남성' },
              { value: 'FEMALE', label: '여성' },
            ]}
          />
        </Form.Item>

        <Form.Item
          label={'이미지'}
          name={'image'}
          rules={[
            {
              required: true,
              message: '이미지를 업로드해주세요',
            },
          ]}
          valuePropName='value'
          getValueFromEvent={(e) => {
            // ImageUpload 컴포넌트에서 직접 string을 반환하는 경우
            if (typeof e === 'string') {
              return e;
            }
            // Antd Upload 컴포넌트의 기본 이벤트 처리
            if (e && e.file && e.file.response) {
              return e.file.response;
            }
            return e;
          }}
        >
          <ImageUpload folder='artist' width={200} height={200} maxSize={5} />
        </Form.Item>

        <Form.Item
          label={'생년월일'}
          name={'birth_date'}
          rules={[
            {
              required: true,
              message: '생년월일을 선택해주세요',
            },
          ]}
          getValueProps={(value) => {
            if (value) {
              return { value: dayjs(value) };
            }
            return { value: birthDate };
          }}
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
          label={'데뷔일'}
          name={'debut_date'}
          getValueProps={(value) => {
            if (value) {
              return { value: dayjs(value) };
            }
            return { value: debutDate };
          }}
          getValueFromEvent={(date) => {
            if (date) {
              return date.utc(true);
            }
            return undefined;
          }}
        >
          <DatePicker style={{ width: '100%' }} />
        </Form.Item>
      </Form>
    </Edit>
  );
}
