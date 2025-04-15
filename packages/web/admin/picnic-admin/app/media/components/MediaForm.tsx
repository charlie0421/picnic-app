'use client';

import { useEffect, useState, useCallback } from 'react';
import { Form, Input, Card, Space, Image, Divider, Typography } from 'antd';
import { useForm } from '@refinedev/antd';
import { useNavigation } from '@refinedev/core';
import { YoutubePreview } from '@/components/features/youtube-preview';
import ImageUpload from '@/components/features/upload';
import { getCdnImageUrl } from '@/lib/image';
import { updatePreview } from '@/lib/media';
import { getLanguageLabel } from '@/lib/utils/language';

const { Text } = Typography;

type MediaFormProps = {
  mode: 'create' | 'edit';
  id?: string;
  formProps: ReturnType<typeof useForm<any>>['formProps'];
  saveButtonProps: ReturnType<typeof useForm<any>>['saveButtonProps'];
  onFinish?: (values: any) => Promise<any>;
  redirectPath?: string;
  record?: any;
};

const MediaForm: React.FC<MediaFormProps> = ({
  mode,
  id,
  formProps,
  saveButtonProps,
  onFinish,
  redirectPath,
  record,
}: MediaFormProps) => {
  const { push } = useNavigation();
  const [previewData, setPreviewData] = useState<any>(null);
  const [isUpdatingPreview, setIsUpdatingPreview] = useState(false);

  // 미리보기 업데이트 핸들러
  const handleUpdatePreview = useCallback(
    async (videoId: string) => {
      if (!videoId) return;

      try {
        setIsUpdatingPreview(true);
        const data = await updatePreview(videoId);
        setPreviewData(data);
      } catch (error) {
        console.error('미리보기 업데이트 오류:', error);
      } finally {
        setIsUpdatingPreview(false);
      }
    },
    [setPreviewData],
  );

  // 비디오 ID 변경 시 미리보기 업데이트
  useEffect(() => {
    const videoId = formProps.form?.getFieldValue('video_id');
    if (videoId) {
      handleUpdatePreview(videoId);
    }
  }, [formProps.form, handleUpdatePreview]);

  // 편집 모드에서 초기 데이터 설정
  useEffect(() => {
    if (mode === 'edit' && formProps.form && formProps.initialValues) {
      // form 필드에 초기값 설정
      formProps.form.setFieldsValue(formProps.initialValues);

      // 유튜브 미리보기 업데이트
      const videoId = formProps.initialValues.video_id;
      if (videoId) {
        handleUpdatePreview(videoId);
      }
    }
  }, [mode, formProps.form, formProps.initialValues, handleUpdatePreview]);

  useEffect(() => {
    if (record?.image) {
      handleUpdatePreview(record.image);
    }
  }, [record?.image, handleUpdatePreview]);

  useEffect(() => {
    if (record?.video) {
      handleUpdatePreview(record.video);
    }
  }, [record?.video, handleUpdatePreview]);

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
        label={`제목 (${getLanguageLabel('ko')})`}
        name={['title', 'ko']}
        rules={[
          {
            required: true,
            message: `${getLanguageLabel('ko')} 제목을 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={`${getLanguageLabel('ko')} 제목을 입력하세요`} />
      </Form.Item>

      <Form.Item
        label={`제목 (${getLanguageLabel('en')})`}
        name={['title', 'en']}
        rules={[
          {
            required: true,
            message: `${getLanguageLabel('en')} 제목을 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={`${getLanguageLabel('en')} 제목을 입력하세요`} />
      </Form.Item>

      <Form.Item
        label={`제목 (${getLanguageLabel('ja')})`}
        name={['title', 'ja']}
        rules={[
          {
            required: true,
            message: `${getLanguageLabel('ja')} 제목을 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={`${getLanguageLabel('ja')} 제목을 입력하세요`} />
      </Form.Item>

      <Form.Item
        label={`제목 (${getLanguageLabel('zh')})`}
        name={['title', 'zh']}
        rules={[
          {
            required: true,
            message: `${getLanguageLabel('zh')} 제목을 입력해주세요.`,
          },
        ]}
      >
        <Input placeholder={`${getLanguageLabel('zh')} 제목을 입력하세요`} />
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
      {previewData && (
        <Card
          title='유튜브 비디오 미리보기'
          variant='outlined'
          size='small'
          style={{ marginBottom: 16, maxWidth: 640 }}
        >
          <Space direction='vertical' style={{ width: '100%' }}>
            {/* 비디오 미리보기 - YoutubePreview 컴포넌트 사용 */}
            <YoutubePreview
              videoUrl={`https://www.youtube.com/watch?v=${previewData.videoId}`}
            />

            {/* 썸네일 미리보기 */}
            <Card title='유튜브 썸네일 미리보기' size='small'>
              <Image
                src={previewData.thumbnail}
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
        variant='outlined'
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
                src={getCdnImageUrl(
                  formProps.form.getFieldValue('thumbnail_url'),
                )}
                alt='커스텀 썸네일'
                style={{ maxWidth: 300, maxHeight: 200 }}
                preview={true}
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
};

export default MediaForm;
