'use client';

import { useEffect, useState } from 'react';
import { Card, Input, Space, Spin } from 'antd';

interface YoutubePreviewProps {
  videoUrl: string;
  onChange?: (data: { videoId: string; thumbnailUrl: string }) => void;
}

export const YoutubePreview: React.FC<YoutubePreviewProps> = ({
  videoUrl,
  onChange,
}) => {
  const [loading, setLoading] = useState(false);
  const [videoId, setVideoId] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!videoUrl) {
      setVideoId('');
      setThumbnailUrl('');
      setError('');
      return;
    }

    try {
      setLoading(true);
      setError('');

      let id = '';

      // YouTube URL 형식 확인 (정규식)
      const youtubeRegex =
        /^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/;
      if (!youtubeRegex.test(videoUrl)) {
        throw new Error('유효한 YouTube URL이 아닙니다.');
      }

      // URL에서 비디오 ID 추출
      if (videoUrl.includes('youtube.com/watch')) {
        const url = new URL(videoUrl);
        id = url.searchParams.get('v') || '';
      } else if (videoUrl.includes('youtu.be/')) {
        const parts = videoUrl.split('youtu.be/');
        id = parts[1]?.split('?')[0] || '';
      }

      if (!id) {
        throw new Error('YouTube 비디오 ID를 추출할 수 없습니다.');
      }

      setVideoId(id);
      const thumbnail = `https://img.youtube.com/vi/${id}/0.jpg`;
      setThumbnailUrl(thumbnail);

      if (onChange) {
        onChange({ videoId: id, thumbnailUrl: thumbnail });
      }
    } catch (err) {
      setError(
        err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.',
      );
      setVideoId('');
      setThumbnailUrl('');
      if (onChange) {
        onChange({ videoId: '', thumbnailUrl: '' });
      }
    } finally {
      setLoading(false);
    }
  }, [videoUrl, onChange]);

  return (
    <Card
      size='small'
      title='YouTube 미리보기'
      style={{ width: '100%', marginBottom: 16 }}
    >
      {loading ? (
        <div style={{ textAlign: 'center', padding: 20 }}>
          <Spin />
        </div>
      ) : error ? (
        <div style={{ color: 'red' }}>{error}</div>
      ) : videoId ? (
        <Space direction='vertical' style={{ width: '100%' }}>
          <div>
            <iframe
              width='100%'
              height='315'
              src={`https://www.youtube.com/embed/${videoId}`}
              title='YouTube video player'
              frameBorder='0'
              allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
              allowFullScreen
            ></iframe>
          </div>
          <Input
            value={`https://img.youtube.com/vi/${videoId}/0.jpg`}
            readOnly
            addonBefore='썸네일 URL'
          />
        </Space>
      ) : (
        <div style={{ padding: 10, color: '#999' }}>
          YouTube URL을 입력하세요.
        </div>
      )}
    </Card>
  );
};
