'use client';

import { useState, useEffect } from 'react';
import { Upload, Button, message } from 'antd';
import { UploadOutlined, LoadingOutlined } from '@ant-design/icons';
import { v4 as uuidv4 } from 'uuid';
import { uploadToS3 } from '@/utils/s3';
import { getImageUrl } from '@/utils/image';

interface ImageUploadProps {
  value?: string;
  onChange?: (url: string) => void;
  bucket?: string;
  folder?: string;
  maxSize?: number; // MB 단위
  width?: number | string;
  height?: number | string;
}

export default function ImageUpload({
  value,
  onChange,
  bucket = 'picnic-images',
  folder = 'vote',
  maxSize = 5, // 기본 5MB
  width = 200,
  height = 200,
}: ImageUploadProps) {
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState<string | undefined>(value);

  useEffect(() => {
    setImageUrl(value);
  }, [value]);

  const beforeUpload = (file: File) => {
    const isImage = file.type.startsWith('image/');
    if (!isImage) {
      message.error('이미지 파일만 업로드할 수 있습니다!');
      return false;
    }

    const isLessThanMaxSize = file.size / 1024 / 1024 < maxSize;
    if (!isLessThanMaxSize) {
      message.error(`이미지 크기는 ${maxSize}MB 이하여야 합니다!`);
      return false;
    }

    return true;
  };

  const customUpload = async (options: any) => {
    const { file, onSuccess, onError } = options;

    try {
      setLoading(true);

      // 고유한 파일명 생성 (UUID + 원본 확장자)
      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const filePath = `${folder}/${fileName}`;

      console.log('업로드할 파일 정보:', {
        fileName,
        filePath,
        fileSize: `${(file.size / 1024 / 1024).toFixed(2)}MB`,
        fileType: file.type,
        bucket,
      });

      // AWS S3에 파일 업로드
      await uploadToS3(file, bucket, filePath);
      console.log('S3 업로드 완료:', filePath);

      // 업로드 성공 핸들링 - filePath만 저장하여 전달
      setImageUrl(filePath);
      if (onChange) {
        onChange(filePath);
        console.log('onChange 호출됨, 전달된 경로:', filePath);
      }

      message.success('이미지가 성공적으로 업로드되었습니다!');
      onSuccess(null, file);
    } catch (error) {
      console.error('업로드 오류 상세 정보:', error);
      message.error('이미지 업로드 중 오류가 발생했습니다.');
      onError(error);
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = () => {
    setImageUrl(undefined);
    if (onChange) {
      onChange('');
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
      {imageUrl && (
        <div style={{ position: 'relative', width, height }}>
          <img
            src={getImageUrl(imageUrl)}
            alt='업로드된 이미지'
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              borderRadius: '8px',
            }}
            onError={(e) => {
              console.error('이미지 로드 오류:', {
                src: e.currentTarget.src,
                imageUrl,
              });
              e.currentTarget.style.border = '1px solid red';
              e.currentTarget.style.padding = '10px';
              e.currentTarget.alt = '이미지 로드 실패';
            }}
          />
          <Button
            danger
            size='small'
            onClick={handleRemove}
            style={{
              position: 'absolute',
              top: '5px',
              right: '5px',
            }}
          >
            삭제
          </Button>
        </div>
      )}

      <Upload
        name='file'
        listType='picture'
        showUploadList={false}
        beforeUpload={beforeUpload}
        customRequest={customUpload}
        disabled={loading}
      >
        <Button
          icon={loading ? <LoadingOutlined /> : <UploadOutlined />}
          disabled={loading}
        >
          {loading ? '업로드 중...' : '이미지 업로드'}
        </Button>
      </Upload>
    </div>
  );
}
