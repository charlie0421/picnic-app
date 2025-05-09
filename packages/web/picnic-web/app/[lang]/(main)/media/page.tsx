'use client';

import React, {useEffect, useState} from 'react';
import {Media} from '@/types/interfaces';
import {getMedias} from '@/utils/api/queries';
import MediaList from '@/components/MediaList';

const MediaPage: React.FC = () => {
  const [medias, setMedias] = useState<Media[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const mediasData = await getMedias();
        setMedias(mediasData);
        setIsLoading(false);
      } catch (error) {
        console.error(
          '미디어 데이터를 가져오는 중 오류가 발생했습니다:',
          error,
        );
        setError('미디어 데이터를 불러오는 중 오류가 발생했습니다.');
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <main className='container mx-auto px-4 py-8'>
      {mounted && (
        <MediaList
          medias={medias}
          isLoading={isLoading}
          error={error}
        />
      )}
    </main>
  );
};

export default MediaPage;
