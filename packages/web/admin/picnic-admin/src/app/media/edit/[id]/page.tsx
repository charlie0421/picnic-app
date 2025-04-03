'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Typography, Card, Space, Image, Divider } from 'antd';
import { useEffect, useState } from 'react';
import { getImageUrl } from '@/utils/image';
import ImageUpload from '@/components/upload';

const { Text } = Typography;

export default function MediaEdit() {
  const { formProps, saveButtonProps, queryResult } = useForm({});
  const [youtubeData, setYoutubeData] = useState<{
    videoId: string;
    thumbnailUrl: string;
  }>({ videoId: '', thumbnailUrl: '' });

  const mediaData = queryResult?.data?.data;

  // 초기 데이터 로드 시 video_id 설정
  useEffect(() => {
    if (mediaData) {
      const videoId = mediaData.video_id || '';

      // videoId가 있으면 관련 데이터 설정
      if (videoId && videoId.trim() !== '') {
        const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/0.jpg`;
        setYoutubeData({
          videoId,
          thumbnailUrl,
        });

        // URL 자동 생성
        const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

        // 폼 값 설정
        formProps.form?.setFieldsValue({
          video_url: videoUrl,
          thumbnail_url: mediaData.thumbnail_url || '', // 기존 썸네일 URL이 있으면 유지
        });
      } else {
        // videoId가 없으면 빈 값으로 설정
        setYoutubeData({
          videoId: '',
          thumbnailUrl: '',
        });

        // 빈 값으로 폼 초기화
        formProps.form?.setFieldsValue({
          video_id: '',
          video_url: '',
          thumbnail_url: mediaData.thumbnail_url || '', // 기존 값 유지 또는 빈 문자열
        });
      }
    }
  }, [mediaData, formProps.form]);

  // video_id가 변경되면 유튜브 미리보기 업데이트
  useEffect(() => {
    const videoId = formProps.form?.getFieldValue('video_id');
    if (videoId) {
      updatePreview(videoId);
    }
  }, [formProps.form]);

  // 비디오 ID로 미리보기 업데이트하는 함수
  const updatePreview = (videoId: string) => {
    // 커스텀 썸네일이 있는지 확인
    const customThumbnail = formProps.form?.getFieldValue('thumbnail_url');

    if (!videoId || videoId.trim() === '') {
      // 비디오 ID가 없을 경우 빈 문자열로 설정
      setYoutubeData({
        videoId: '',
        thumbnailUrl: '',
      });

      // 폼 필드도 빈 문자열로 업데이트 (단, 커스텀 썸네일이 있다면 유지)
      formProps.form?.setFieldsValue({
        video_id: '',
        video_url: '',
        thumbnail_url: customThumbnail || '', // 커스텀 썸네일이 있으면 유지
      });
      return;
    }

    // 유튜브 ID가 있으면 썸네일 URL 생성
    const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/0.jpg`;
    setYoutubeData({
      videoId,
      thumbnailUrl,
    });

    // URL도 자동으로 구성 (hidden 필드 업데이트)
    const videoUrl = `https://www.youtube.com/watch?v=${videoId}`;

    // 커스텀 썸네일이 없을 경우에만 유튜브 썸네일 사용
    if (!customThumbnail) {
      formProps.form?.setFieldsValue({
        video_url: videoUrl,
        thumbnail_url: '', // 커스텀 썸네일이 없으면 빈 문자열 (유튜브 썸네일은 자동으로 적용)
      });
    } else {
      // 커스텀 썸네일이 있으면 video_url만 업데이트
      formProps.form?.setFieldsValue({
        video_url: videoUrl,
      });
    }
  };

  return (
    <Edit saveButtonProps={saveButtonProps}>
      <Form {...formProps} layout='vertical'>
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
              updatePreview(id);
            }}
            onBlur={(e) => {
              // 필드를 떠날 때도 미리보기 업데이트
              updatePreview(e.target.value);
            }}
            onPressEnter={(e) => {
              // Enter 키 누를 때도 미리보기 업데이트
              updatePreview((e.target as HTMLInputElement).value);
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
              {/* 비디오 미리보기 */}
              <div
                style={{
                  position: 'relative',
                  paddingBottom: '56.25%',
                  height: 0,
                  overflow: 'hidden',
                }}
              >
                <iframe
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                  }}
                  src={`https://www.youtube.com/embed/${youtubeData.videoId}`}
                  title='YouTube video player'
                  frameBorder='0'
                  allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
                  allowFullScreen
                ></iframe>
              </div>

              {/* 썸네일 미리보기 */}
              <Card title='유튜브 썸네일 미리보기' size='small'>
                <Image
                  src={youtubeData.thumbnailUrl}
                  alt='유튜브 썸네일'
                  style={{ maxWidth: 300, maxHeight: 200 }}
                />
                <Text
                  type='secondary'
                  style={{ display: 'block', marginTop: 8 }}
                >
                  유튜브에서 자동 생성된 썸네일입니다.
                </Text>
              </Card>
            </Space>
          </Card>
        )}

        <Divider orientation='left'>커스텀 썸네일</Divider>

        {/* 커스텀 썸네일 섹션 */}
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
                  src={getImageUrl(
                    formProps.form.getFieldValue('thumbnail_url'),
                  )}
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
                    updatePreview(videoId);
                  }
                }}
              />
            </Form.Item>
          </Space>
        </Card>
      </Form>
    </Edit>
  );
}
