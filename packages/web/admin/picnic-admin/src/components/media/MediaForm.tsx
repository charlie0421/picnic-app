'use client';

import { useEffect, useState } from 'react';
import { Form, Input, Card, Space, Image, Divider, Typography } from 'antd';
import { useForm } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { YoutubePreview } from '@/components/youtube-preview';
import ImageUpload from '@/components/upload';
import { getImageUrl } from '@/utils/image';
import { updatePreview } from '@/utils/media';

const { Text } = Typography;

type MediaFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<any>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<any>>['saveButtonProps'];
  onFinish?: (values: any) => Promise<any>;
  redirectPath?: string;
};

export default function MediaForm({
  mode,
  id,
  formProps,
  saveButtonProps,
  onFinish,
  redirectPath,
}: MediaFormProps) {
  const { push } = useNavigation();
  const [youtubeData, setYoutubeData] = useState<{
    videoId: string;
    thumbnailUrl: string;
  }>({ videoId: '', thumbnailUrl: '' });

  // video_id가 변경되면 유튜브 미리보기 업데이트
  useEffect(() => {
    const videoId = formProps.form?.getFieldValue('video_id');
    if (videoId) {
      handleUpdatePreview(videoId);
    }
  }, [formProps.form]);

  // 편집 모드에서 초기 데이터 설정
  useEffect(() => {
    if (mode === 'edit' && formProps.form && formProps.initialValues) {
      console.log('MediaForm: 편집 모드 초기값 설정', formProps.initialValues);
      // form 필드에 초기값 설정
      formProps.form.setFieldsValue(formProps.initialValues);

      // 유튜브 미리보기 업데이트
      const videoId = formProps.initialValues.video_id;
      if (videoId) {
        handleUpdatePreview(videoId);
      }
    }
  }, [mode, formProps.form, formProps.initialValues]);

  // 비디오 ID로 미리보기 업데이트하는 함수
  const handleUpdatePreview = (videoId: string) => {
    const result = updatePreview(videoId, formProps.form);
    setYoutubeData(result);
  };

  return (
    <Form
      {...formProps}
      layout='vertical'
      initialValues={
        mode === 'edit'
          ? formProps.initialValues || {}
          : { title: { ko: '', en: '', ja: '', zh: '' } }
      }
    >
      <Divider orientation='left'>제목 정보</Divider>

      <Form.Item
        label={'제목 (한국어)'}
        name={['title', 'ko']}
        rules={[
          {
            required: true,
            message: '한국어 제목을 입력해주세요.',
          },
        ]}
      >
        <Input placeholder='한국어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item
        label={'제목 (영어)'}
        name={['title', 'en']}
        rules={[
          {
            required: true,
            message: '영어 제목을 입력해주세요.',
          },
        ]}
      >
        <Input placeholder='영어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item
        label={'제목 (일본어)'}
        name={['title', 'ja']}
        rules={[
          {
            required: true,
            message: '일본어 제목을 입력해주세요.',
          },
        ]}
      >
        <Input placeholder='일본어 제목을 입력하세요' />
      </Form.Item>

      <Form.Item
        label={'제목 (중국어)'}
        name={['title', 'zh']}
        rules={[
          {
            required: true,
            message: '중국어 제목을 입력해주세요.',
          },
        ]}
      >
        <Input placeholder='중국어 제목을 입력하세요' />
      </Form.Item>

      <Divider orientation='left'>유튜브 비디오 정보</Divider>

      <Form.Item
        label={'비디오 ID (YouTube)'}
        name={'video_id'}
        tooltip="YouTube 비디오 ID를 입력해주세요. 예: 유튜브 주소가 https://www.youtube.com/watch?v=abcdefg 라면 'abcdefg'가 ID입니다."
        rules={[
          {
            required: true,
            message: '비디오 ID를 입력해주세요.',
          },
        ]}
      >
        <Input
          placeholder='예: dQw4w9WgXcQ'
          onChange={(e) => {
            const id = e.target.value;
            formProps.form?.setFieldsValue({ video_id: id });
            // 입력 즉시 미리보기 업데이트
            handleUpdatePreview(id);
          }}
          onBlur={(e) => {
            // 필드를 떠날 때도 미리보기 업데이트
            handleUpdatePreview(e.target.value);
          }}
          onPressEnter={(e) => {
            // Enter 키 누를 때도 미리보기 업데이트
            handleUpdatePreview((e.target as HTMLInputElement).value);
          }}
        />
      </Form.Item>

      {/* 유튜브 URL은 hidden 필드로 처리 (video_id 기반으로 자동 생성) */}
      <Form.Item name={'video_url'} hidden>
        <Input />
      </Form.Item>

      {/* 썸네일 URL hidden 필드로 처리 */}
      <Form.Item name={'thumbnail_url'} hidden>
        <Input />
      </Form.Item>

      {/* 유튜브 미리보기 표시 */}
      {youtubeData.videoId && (
        <Card
          title='유튜브 비디오 미리보기'
          size='small'
          style={{ marginBottom: 16, maxWidth: 640 }}
        >
          <Space direction='vertical' style={{ width: '100%' }}>
            {/* 비디오 미리보기 - YoutubePreview 컴포넌트 사용 */}
            <YoutubePreview
              videoUrl={`https://www.youtube.com/watch?v=${youtubeData.videoId}`}
              onChange={(data) => {
                setYoutubeData(data);
              }}
            />

            {/* 썸네일 미리보기 */}
            <Card title='유튜브 썸네일 미리보기' size='small'>
              <Image
                src={youtubeData.thumbnailUrl}
                alt='유튜브 썸네일'
                style={{ maxWidth: 300, maxHeight: 200 }}
              />
              <Text type='secondary' style={{ display: 'block', marginTop: 8 }}>
                유튜브에서 자동 생성된 썸네일입니다.
              </Text>
            </Card>
          </Space>
        </Card>
      )}

      <Card
        title='커스텀 썸네일'
        size='small'
        style={{ marginBottom: 16, maxWidth: 640 }}
      >
        <Space direction='vertical' style={{ width: '100%' }}>
          {/* 커스텀 썸네일 미리보기 */}
          {formProps.form?.getFieldValue('thumbnail_url') && (
            <div style={{ marginBottom: 16 }}>
              <Text strong style={{ display: 'block', marginBottom: 8 }}>
                현재 커스텀 썸네일:
              </Text>
              <Image
                src={getImageUrl(formProps.form.getFieldValue('thumbnail_url'))}
                alt='커스텀 썸네일'
                style={{ maxWidth: 300, maxHeight: 200 }}
              />
            </div>
          )}

          {/* 커스텀 썸네일 업로드 */}
          <Form.Item
            label='커스텀 썸네일 업로드'
            tooltip='유튜브 썸네일 대신 사용할 이미지를 업로드하세요. 업로드하지 않으면 유튜브 썸네일이 사용됩니다.'
            style={{ marginBottom: 0 }}
          >
            <ImageUpload
              folder='media/thumbnails'
              width={300}
              height={200}
              value={formProps.form?.getFieldValue('thumbnail_url')}
              onChange={(value) => {
                formProps.form?.setFieldsValue({ thumbnail_url: value });
                // 미리보기 업데이트가 필요하면 현재 video_id로 다시 업데이트
                const videoId = formProps.form?.getFieldValue('video_id');
                if (videoId) {
                  handleUpdatePreview(videoId);
                }
              }}
            />
          </Form.Item>
        </Space>
      </Card>
    </Form>
  );
}
